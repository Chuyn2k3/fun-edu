import 'package:flutter/material.dart';
import 'package:fun_edu/constant/dimens.dart';
import 'package:fun_edu/widget/base_responsive_screen.dart';
import 'package:fun_edu/widget/menu/portal_master_layout.dart';
import 'package:fun_edu/widget/responsive.dart';
import 'package:responsive_framework/responsive_framework.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return PortalMasterLayout(
      body: Responsive(
        mobile: _buildBodyPageWidget(context),
        desktop: _buildBodyPageWidget(context),
      ),
    );
  }

  Widget _buildBodyPageWidget(BuildContext context) {
    final margin = Dimens.instance.space3(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: margin, vertical: margin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildIntroSection(),
                const SizedBox(height: 32),
                _buildFeatureSection(),
                const SizedBox(height: 32),
                _buildContactSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      child: const Text(
        "Giới thiệu Fun Edu",
        style: TextStyle(
          fontFamily: 'LilitaOne',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Fun Edu là ứng dụng học toán và trò chơi tư duy dành cho trẻ em, giúp bé phát triển khả năng nhận biết số, tư duy logic và giải trí lành mạnh.",
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
        SizedBox(height: 16),
        Text(
          "Các chức năng nổi bật:",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
        ),
      ],
    );
  }

  Widget _buildFeatureSection() {
    return const Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _FeatureCard(
          icon: Icons.tag,
          color: Colors.orangeAccent,
          title: "Học số",
          description: "Làm quen, nhận biết, ghép số, sắp xếp số, đếm hình.",
        ),
        _FeatureCard(
          icon: Icons.compare_arrows,
          color: Colors.purpleAccent,
          title: "So sánh",
          description: "So sánh số, so sánh bằng hình ảnh, luyện tư duy.",
        ),
        _FeatureCard(
          icon: Icons.calculate,
          color: Colors.greenAccent,
          title: "Tính toán",
          description: "Cộng trừ, luyện tập, thử thách bản thân.",
        ),
        _FeatureCard(
          icon: Icons.sports_esports,
          color: Colors.blueAccent,
          title: "Trò chơi",
          description:
              "Khủng long, đố vui, giải cứu đại dương và nhiều game hấp dẫn.",
        ),
        _FeatureCard(
          icon: Icons.picture_as_pdf,
          color: Colors.redAccent,
          title: "Tài liệu PDF",
          description: "Xem và tải tài liệu học tập.",
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Liên hệ đội ngũ phát triển:",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple),
        ),
        SizedBox(height: 8),
        Text(
          "• Email: ibmelab@gmail.com\n"
          "• Webside: https://lab.ibme.edu.vn\n",
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        SizedBox(height: 16),
        Text(
          "Fun Edu luôn lắng nghe ý kiến đóng góp để hoàn thiện sản phẩm tốt hơn cho các bé!",
          style: TextStyle(
              fontSize: 16,
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                radius: 32,
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'LilitaOne',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
