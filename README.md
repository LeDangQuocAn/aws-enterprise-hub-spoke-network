## Tóm tắt

Tài liệu này là báo cáo kiến trúc sau triển khai (as-built) của hệ thống mạng EduCloud trên nền tảng AWS, được xây dựng theo mô hình Hub-and-Spoke và quản trị bằng Infrastructure as Code (Terraform).

Trọng tâm của hệ thống đã triển khai:
- Phân đoạn mạng theo 5 VPC chức năng độc lập.
- Định tuyến tập trung thông qua AWS Transit Gateway (TGW).
- Tập trung luồng outbound qua Egress VPC và NAT Gateway theo từng Availability Zone.
- Tiếp nhận luồng inbound qua Ingress VPC với ALB (kết hợp WAF).
- Tăng cường bảo mật và quan sát hệ thống bằng SSM VPC Endpoints và VPC Flow Logs.

---

## 1. Mục tiêu và phạm vi báo cáo

### 1.1 Mục tiêu

Báo cáo nhằm phản ánh trung thực trạng thái hạ tầng đã được triển khai trong mã Terraform hiện tại, phục vụ mục đích đánh giá học thuật và nghiệm thu kỹ thuật.

### 1.2 Phạm vi

Nội dung trong README này chỉ mô tả các thành phần đã có thực trong hệ thống as-built, đồng thời chỉ ra các hạng mục mục tiêu chưa hoàn tất để làm cơ sở cho giai đoạn nâng cấp tiếp theo.

Tổng quan hiện trạng:
- Đã triển khai: TGW core, 5 VPC, TGW attachments, định tuyến trung tâm, NAT egress theo AZ, ALB, EC2 App tier, RDS MySQL, WAF, VPC Flow Logs.
- Chưa thấy trong code hiện tại: Auto Scaling Group (ASG), RDS Multi-AZ bật thật sự, TGW blackhole routes, CloudWatch Dashboard chuyên biệt cho TGW.

---

## 2. Đối chiếu yêu cầu nghiệp vụ và kỹ thuật

### 2.1 Bối cảnh nghiệp vụ

EduCloud là doanh nghiệp EdTech đang chuyển dịch toàn bộ hạ tầng lên AWS. Yêu cầu cốt lõi gồm: bảo mật cao, khả năng mở rộng tốt, quản trị tập trung, và khả năng vận hành ổn định với đội ngũ kỹ sư tinh gọn.

### 2.2 Đối chiếu mục tiêu kỹ thuật

| Mục tiêu kỹ thuật | Trạng thái as-built | Nhận định |
|---|---|---|
| High Availability (Multi-AZ) | Đạt một phần | Mạng và NAT đã phân bố đa AZ; tầng ứng dụng chưa dùng ASG. |
| Giảm blast radius | Đã đạt | Phân đoạn rõ theo 5 VPC chức năng. |
| Định tuyến tập trung | Đã đạt | TGW route table tập trung với cơ chế association/propagation rõ ràng. |
| Tự động hóa IaC | Đã đạt | Terraform + Terraform Cloud + GitHub Actions đã hiện diện trong hệ thống. |
| Tăng cứng bảo mật | Đạt một phần | Đã có WAF, Security Groups, SSM endpoints, Flow Logs; chưa thấy blackhole routes theo Zero Trust matrix. |

---

## 3. Thiết kế logic (As-Built)

### 3.1 Mô hình Hub-and-Spoke

Kiến trúc sử dụng AWS Transit Gateway làm nút trung tâm điều phối định tuyến. Năm VPC spoke được kết nối vào TGW thông qua các subnet chuyên dụng cho attachment.

### 3.2 Phân đoạn mạng chức năng

| VPC | Vai trò thực tế |
|---|---|
| Ingress VPC | Vùng biên public, chứa ALB internet-facing. |
| Egress VPC | Vùng thoát internet tập trung, chứa NAT Gateway theo AZ. |
| App VPC | Vùng private cho ứng dụng và cơ sở dữ liệu. |
| Shared Services VPC | Vùng dịch vụ dùng chung nội bộ. |
| DMZ VPC | Vùng quản trị/điều khiển private, chứa các SSM interface endpoints. |

### 3.3 Chiến lược địa chỉ IP đã áp dụng

- Supernet toàn cục: `10.10.0.0/16`.
- CIDR cho từng VPC được tách động bằng hàm `cidrsubnet()` thay vì hard-code thủ công.
- Mỗi VPC có nhóm subnet riêng cho TGW attachment (`intra_subnets`) theo từng AZ.

Nhận định học thuật:
- Cách tách CIDR động giúp giảm rủi ro chồng lấn mạng và tăng khả năng tái sử dụng module khi mở rộng quy mô.
- Việc tách riêng subnet cho attachment giúp kiểm soát route domain minh bạch hơn.

---

## 4. Thiết kế vật lý và triển khai (As-Built)

### 4.1 Lõi kết nối mạng

Các thành phần đã triển khai:
- 01 AWS Transit Gateway (core hub).
- 05 VPC tạo từ module chuẩn `terraform-aws-modules/vpc/aws`.
- 05 TGW VPC attachments.
- 01 TGW route table trung tâm cho toàn bộ spoke.
- Tuyến mặc định `0.0.0.0/0` từ TGW về attachment của Egress VPC.
- Tuyến từ private subnets (App/DMZ/Shared-Services) đi TGW.
- NAT Gateway theo từng AZ tại Egress VPC.

### 4.2 Ingress và tầng ứng dụng

Đã triển khai:
- ALB internet-facing tại Ingress VPC.
- Listener HTTP (port 80) chuyển tiếp đến target group.
- App tier chạy trên EC2 private subnets trong App VPC.
- Target group sử dụng `target_type = ip`, gắn private IP của EC2.

Lưu ý kỹ thuật:
- Tầng ứng dụng hiện chưa chuyển sang Auto Scaling Group; vẫn đang ở mô hình EC2 tĩnh theo số AZ.

### 4.3 Cơ sở dữ liệu

Đã triển khai:
- Amazon RDS MySQL trong private subnets thông qua DB subnet group của App VPC.
- Security Group tách riêng cho DB tier.

Lưu ý kỹ thuật:
- Tham số `multi_az` trong trạng thái hiện tại là `false`.

### 4.4 Kiểm soát bảo mật

Đã triển khai:
- Security Groups theo từng lớp: ALB, Web, DB, DMZ-SSM.
- Bộ SSM interface endpoints (`ssm`, `ssmmessages`, `ec2messages`) trong DMZ VPC.
- AWS WAFv2 Web ACL gắn trực tiếp vào ALB với managed rule groups.

### 4.5 Quan sát và nhật ký

Đã triển khai:
- CloudWatch Log Group cho VPC Flow Logs.
- IAM role/policy chuyên dụng cho dịch vụ flow logs ghi log.
- Bật VPC Flow Logs trên toàn bộ các VPC trong topology hiện tại.

Lưu ý kỹ thuật:
- Chưa có tài nguyên `aws_cloudwatch_dashboard` chuyên biệt cho TGW trong mã hiện tại.

---

## 5. Sơ đồ kiến trúc cuối cùng (As-Built)

```text
                               +----------------------+
                               |    Internet Users    |
                               +----------+-----------+
                                          |
                                          v
                               +----------------------+
                               |     Ingress VPC      |
                               |      ALB + WAF       |
                               +----------+-----------+
                                          |
                                          v
                               +----------------------+
                               | AWS Transit Gateway  |
                               |        (Hub)         |
                               +----+----+----+----+--+
                                    |    |    |    |
          +-------------------------+    |    |    +-------------------------+
          |                              |    |                              |
          v                              v    v                              v
   +-------------------+        +-------------------+        +------------------------+
   |      App VPC      |        |    Egress VPC     |        | Shared Services VPC    |
   | EC2 App Instances |        | NAT Gateway/AZ    |        | Internal Services      |
   |    RDS MySQL      |        | Internet Exit     |        |                        |
   +---------+---------+        +---------+---------+        +------------------------+
             |                             |
             |                             v
             |                    +----------------------+
             |                    |   Internet Egress    |
             |                    +----------------------+
             |
             v
   +------------------------+
   |       DMZ VPC          |
   | SSM Interface Endpoints|
   |   Management Plane     |
   +------------------------+
```

---

## 6. Danh mục output đã triển khai

Các output quan trọng đang có trong Terraform:
- `transit_gateway_id`, `transit_gateway_arn`
- `ingress_alb_dns_name`, `ingress_alb_arn`
- `app_target_group_arn`
- `rds_endpoint`
- `vpc_flow_logs_log_group_name`
- `app_instance_private_ips`

---

## 7. Phân tích khoảng cách so với trạng thái Enterprise mục tiêu

| Hạng mục mục tiêu | Trạng thái hiện tại | Hướng nâng cấp |
|---|---|---|
| ASG cho App tier | Chưa có | Chuyển từ EC2 tĩnh sang Launch Template + Auto Scaling Group. |
| RDS Multi-AZ | Chưa bật (false) | Bật `multi_az = true` và chuẩn hóa backup/maintenance window. |
| TGW blackhole routes | Chưa thấy | Bổ sung `aws_ec2_transit_gateway_route` với `blackhole = true` theo ma trận Zero Trust. |
| Dashboard giám sát TGW | Chưa thấy | Bổ sung `aws_cloudwatch_dashboard` và các metric TGW trọng yếu. |

---

## 8. Kết luận

Hệ thống mạng EduCloud đã đạt mức nền tảng triển khai sản xuất ở các trục chính: định tuyến tập trung, phân đoạn an toàn, kiểm soát truy cập theo lớp, và ghi log đồng bộ. README v2 này được hiệu chỉnh theo hướng học thuật và bám sát trạng thái hạ tầng thực tế trong mã Terraform.

Để tiến tới trạng thái enterprise hoàn chỉnh, lộ trình ưu tiên gồm: hoàn thiện ASG cho tầng ứng dụng, bật RDS Multi-AZ, bổ sung TGW blackhole policy theo mô hình Zero Trust, và xây dựng dashboard giám sát lưu lượng chuyên sâu.
