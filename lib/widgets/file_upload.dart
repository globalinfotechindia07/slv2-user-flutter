import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class FileUpload extends StatefulWidget {
  final String label;
  final String? error;
  final File? value;
  final ValueChanged<File?> onFileSelected;
  final VoidCallback onRemove;

  const FileUpload({
    Key? key,
    required this.label,
    required this.onFileSelected,
    required this.onRemove,
    this.value,
    this.error,
  }) : super(key: key);

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  File? _previewFile;

  @override
  void initState() {
    super.initState();
    if (widget.value != null && _isImage(widget.value!)) {
      _previewFile = widget.value;
    }
  }

  bool _isImage(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  String _fileName(File file) => file.path.split('/').last;

  
  void _handleFileSelected(File file) {
    if (_isImage(file)) {
      setState(() => _previewFile = file); 
    } else {
      setState(() => _previewFile = null); 
    }
    widget.onFileSelected(file);
  }

  void _handleRemove() {
    setState(() => _previewFile = null);
    widget.onRemove();
  }

  Future<void> _showPickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload Document',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFFDC2626)),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80,
                );
                if (picked != null) _handleFileSelected(File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFFDC2626)),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (picked != null) _handleFileSelected(File(picked.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined,
                  color: Color(0xFFDC2626)),
              title: const Text('Choose PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf'],
                );
                if (result != null && result.files.single.path != null) {
                  _handleFileSelected(File(result.files.single.path!));
                }
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showPickerOptions,
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.error != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: _buildContent(),
          ),
        ),
        if (widget.error != null && widget.error!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Color(0xFFEF4444)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.error!,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFFEF4444)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_previewFile != null) {
      return _ImagePreview(file: _previewFile!, onRemove: _handleRemove);
    } else if (widget.value != null) {
      return _FileNameRow(
          fileName: _fileName(widget.value!), onRemove: _handleRemove);
    } else {
      return const _EmptyState();
    }
  }
}

class _ImagePreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _ImagePreview({Key? key, required this.file, required this.onRemove})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              height: 160, 
              fit: BoxFit.contain,
            ),
          ),
        ),
        GestureDetector(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

// ─── File Name Row ────────────────────────────────────────────────────────────

class _FileNameRow extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const _FileNameRow(
      {Key? key, required this.fileName, required this.onRemove})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.insert_drive_file_outlined,
            size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            fileName,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 18, color: Color(0xFFEF4444)),
        ),
      ],
    );
  }
}



class _EmptyState extends StatelessWidget {
  const _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.upload_outlined, size: 32, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'Tap to upload',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          'PDF, JPG, JPEG, PNG up to 5MB',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}