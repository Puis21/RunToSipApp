import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:run_to_sip_app/colors/app_colors.dart';
import 'package:run_to_sip_app/widgets/baseEndDrawer.dart';
import 'package:run_to_sip_app/widgets/baseAppBar.dart';
import 'dart:convert';

class ContactForm extends StatefulWidget {
  const ContactForm({super.key});

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSending = false;

  Future<void> sendEmail() async {
    const serviceId = 'service_tr549et';
    const templateId = 'template_vry2uhm';
    const publicKey = 'Rjfcs5chBb-lcYCXh';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    setState(() {
      _isSending = true;
    });

    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'user_name': _nameController.text,
          'user_email': _emailController.text,
          'user_subject': _subjectController.text,
          'user_message': _messageController.text,
        },
      }),
    );

    setState(() {
      _isSending = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent successfully!')),
      );
      _formKey.currentState?.reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: ${response.body}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: buildBaseAppBar(context, "Report a Bug"),
      endDrawer: buildBaseEndDrawer(context),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                keyboardType: TextInputType.name,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                validator: (v) => v == null || !v.contains('@')
                    ? 'Valid email required'
                    : null,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _subjectController,
                label: 'Subject',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: _messageController,
                label: 'Message',
                maxLines: 5,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _isSending
                        ? null
                        : LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.blue.shade400,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    color: _isSending
                        ? Colors.grey.shade400
                        : null, // fallback color while sending
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    onPressed: _isSending
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              sendEmail();
                            }
                          },
                    child: _isSending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade700, width: 2),
        ),
      ),
    );
  }
}
