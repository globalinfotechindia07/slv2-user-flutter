import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SecureImage extends StatefulWidget {
  final String folder;
  final String filename;
  final double? width;
  final double? height;
  final BoxFit fit;

  const SecureImage({
    Key? key,
    required this.folder,
    required this.filename,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  State<SecureImage> createState() => _SecureImageState();
}

class _SecureImageState extends State<SecureImage> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchPresignedUrl();
  }

  @override
  void didUpdateWidget(covariant SecureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filename != widget.filename) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _imageUrl = null;
      });
      _fetchPresignedUrl();
    }
  }

  Future<void> _fetchPresignedUrl() async {
    if (widget.filename.isEmpty) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
      return;
    }

    if (widget.filename.startsWith('http')) {
      if (mounted) setState(() { _imageUrl = widget.filename; _isLoading = false; });
      return;
    }

    try {
      final token = await AuthService.getAccessToken();
      debugPrint('=== SECURE IMAGE ===');
      debugPrint('token null? ${token == null}');
      debugPrint('token empty? ${token?.isEmpty}');
      debugPrint('token value: $token');
      debugPrint('folder: ${widget.folder}');
      debugPrint('filename: ${widget.filename}');
      debugPrint('====================');
      final basename = widget.filename.split('/').last.split('\\').last;
      final uri = Uri.parse(
        '${ApiConstants.newAuthBaseUrl}/api/v2/mobile/files/presign'
        '?folder=${widget.folder}&filename=$basename',
      );

      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
      });
        debugPrint('Response : ${response}');
        debugPrint('PRESIGN STATUS: ${response.statusCode}');
        debugPrint('PRESIGN BODY: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final path = data['data']['url'] as String;
          final finalUrl = '${ApiConstants.newAuthBaseUrl}/api/v2/mobile$path';
          debugPrint('PRESIGN path: $path');
          debugPrint('FINAL image URL: $finalUrl');
          if (mounted) {
            setState(() {
              _imageUrl = finalUrl;
              _isLoading = false;
            });
          }
        } else {
          throw Exception('Presign failed');
        }
      } else {
        throw Exception('API error ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SecureImage error: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _imageUrl == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.person, color: Color(0xFF94A3B8)),
      );
    }

    return Image.network(
      _imageUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                      progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFE2E8F0),
        child: const Icon(Icons.person, color: Color(0xFF94A3B8)),
      ),
    );
  }
}