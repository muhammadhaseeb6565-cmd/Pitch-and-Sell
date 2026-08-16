import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class PitchGeneratorScreen extends StatefulWidget {
  const PitchGeneratorScreen({super.key});

  @override
  State<PitchGeneratorScreen> createState() => _PitchGeneratorScreenState();
}

class _PitchGeneratorScreenState extends State<PitchGeneratorScreen> {
  final _prodNameController = TextEditingController();
  final _sellingPointController = TextEditingController();
  String _tone = 'exciting';
  String _lang = 'ur';
  bool _isLoading = false;
  String _generatedScript = '';
  List<dynamic> _tips = [];

  Future<void> _handleGenerate() async {
    if (_prodNameController.text.isEmpty || _sellingPointController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedScript = '';
    });

    try {
      final response = await ApiService.generatePitchScript({
        'productName': _prodNameController.text,
        'sellingPoint': _sellingPointController.text,
        'tone': _tone,
        'language': _lang,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedScript = data['script'];
          _tips = data['tips'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff1e1e1e),
        elevation: 0,
        title: const Text('AI Pitch Script Generator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Input product details to get a high-converting 15-second script for your short commerce video.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Form Fields
            TextField(
              controller: _prodNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Product Name',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sellingPointController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Key Selling Point (e.g., RGB Lights, Active Noise Cancellation)',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 20),

            // Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tone,
                    decoration: const InputDecoration(labelText: 'Tone', labelStyle: TextStyle(color: Colors.grey)),
                    dropdownColor: const Color(0xff1e1e1e),
                    items: const [
                      DropdownMenuItem(value: 'exciting', child: Text('Exciting / High Energy')),
                      DropdownMenuItem(value: 'professional', child: Text('Professional / Formal')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _tone = val);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _lang,
                    decoration: const InputDecoration(labelText: 'Language', labelStyle: TextStyle(color: Colors.grey)),
                    dropdownColor: const Color(0xff1e1e1e),
                    items: const [
                      DropdownMenuItem(value: 'ur', child: Text('Roman Urdu')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _lang = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFF5722),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleGenerate,
                icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.psychology, color: Colors.white),
                label: Text(
                  _isLoading ? 'Generating Script...' : 'Generate AI Script',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            // Display Results
            if (_generatedScript.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Your generated 15s Pitch Script:',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff1e1e1e),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffFF5722).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _generatedScript,
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6, fontFamily: 'monospace'),
                    ),
                    const Divider(color: Colors.white10, height: 32),
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedScript));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Script copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, color: Color(0xffFF5722), size: 18),
                      label: const Text('Copy Script', style: TextStyle(color: Color(0xffFF5722), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            // Display Tips
            if (_tips.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Recording Tips:',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xffFF5722), fontSize: 16)),
                    Expanded(child: Text(tip, style: const TextStyle(color: Colors.grey, fontSize: 13))),
                  ],
                ),
              )),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
