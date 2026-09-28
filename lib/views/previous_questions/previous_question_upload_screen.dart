import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// English Comment: Dedicated Upload Screen for previous year questions.
class PreviousQuestionUploadScreen extends StatefulWidget {
  const PreviousQuestionUploadScreen({super.key});

  @override
  State<PreviousQuestionUploadScreen> createState() => _PreviousQuestionUploadScreenState();
}

class _PreviousQuestionUploadScreenState extends State<PreviousQuestionUploadScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _titleController = TextEditingController();
  final _examNameController = TextEditingController();
  final _examYearController = TextEditingController();
  final _jobCategoryController = TextEditingController();

  String _selectedSubCategory = 'General';
  FilePickerResult? _pickedFile;
  bool _isUploading = false;

  final List<String> _subCategories = ['General', 'IT'];

  Future<void> _pickPDF() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      setState(() {
        _pickedFile = result;
      });
    }
  }

  Future<void> _uploadAndSave() async {
    if (_titleController.text.isEmpty || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title and select a PDF file.')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileBytes = _pickedFile!.files.first.bytes;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.files.first.name}';
      final String storagePath = 'PREVIOUS_YEAR_QUESTIONS/$_selectedSubCategory/$fileName';

      if (kIsWeb) {
        await _supabase.storage.from('materials').uploadBinary(storagePath, fileBytes!);
      } else {
        final filePath = _pickedFile!.files.first.path;
        if (filePath != null) {
          await _supabase.storage.from('materials').upload(storagePath, File(filePath));
        } else if (fileBytes != null) {
          await _supabase.storage.from('materials').uploadBinary(storagePath, fileBytes);
        }
      }

      final String filePublicUrl = _supabase.storage.from('materials').getPublicUrl(storagePath);

      await _supabase.from('previous_questions').insert({
        'title': _titleController.text.trim(),
        'category': _selectedSubCategory,
        'exam_name': _examNameController.text.trim(),
        'exam_year': int.tryParse(_examYearController.text.trim()),
        'job_category': _jobCategoryController.text.trim(),
        'file_url': filePublicUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question Paper Uploaded Successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Previous Year Question')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Question Title (e.g. Bangladesh Bank AD 2023)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubCategory,
              decoration: const InputDecoration(
                labelText: 'Folder / Sub-Category',
                border: OutlineInputBorder(),
              ),
              items: _subCategories.map((String subCat) {
                return DropdownMenuItem<String>(
                  value: subCat,
                  child: Text(subCat),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedSubCategory = val!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _examNameController,
              decoration: const InputDecoration(
                labelText: 'Exam Name (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _examYearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Exam Year (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _jobCategoryController,
              decoration: const InputDecoration(
                labelText: 'Job Category (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickPDF,
              icon: const Icon(Icons.attach_file),
              label: Text(_pickedFile == null ? 'Select PDF File' : _pickedFile!.files.first.name),
            ),
            const SizedBox(height: 24),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _uploadAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B4EE6),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Upload & Save Question'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}