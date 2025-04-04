import 'dart:io';
import 'dart:convert'; // For jsonEncode and jsonDecode.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:objectiq/model/history_item.dart';
import 'package:objectiq/provider/history_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; // For HTTP calls

/// This class uses your provided method to request storage permission
/// and then returns the external storage path (Download folder on Android).
class FileStorage {
  static Future<String> getExternalDocumentPath() async {
    // Check storage permission
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    Directory directory = Directory("");
    if (Platform.isAndroid) {
      // On Android, use the Download folder
      directory = Directory("/storage/emulated/0/Download");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }
    final exPath = directory.path;
    print("Saved Path: $exPath");
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  /// Writes bytes to a file with the given name.
  static Future<File> writeFileBytes(List<int> bytes, String name) async {
    final path = await _localPath;
    File file = File('$path/$name');
    print("Saving file to: $path/$name");
    return file.writeAsBytes(bytes, flush: true);
  }
}

class AnalyzePage extends StatefulWidget {
  final String? imagePath;

  const AnalyzePage({super.key, this.imagePath});

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.imagePath != null) {
      _selectedImage = File(widget.imagePath!);
    }
  }

  /// Updated _pickImage: if source is camera, request permission and open camera.
  /// On web, pass webOptions to try opening the camera.
  Future<void> _pickImage([ImageSource? source]) async {
    source ??= ImageSource.gallery;
    if (source == ImageSource.camera) {
      if (kIsWeb) {
        try {
          // Try to request camera access.
          await html.window.navigator.mediaDevices!
              .getUserMedia({'video': true});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Camera not available or permission denied on web.')),
          );
          return; // Exit if camera access fails.
        }
      } else if (Platform.isAndroid || Platform.isIOS) {
        var cameraStatus = await Permission.camera.status;
        if (!cameraStatus.isGranted) {
          cameraStatus = await Permission.camera.request();
          if (!cameraStatus.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera permission not granted')),
            );
            return;
          }
        }
      }
    }
    final XFile? image = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _analysisResult = null; // Clear previous analysis.
      });
    }
  }

  /// Show bottom sheet for upload options.
  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
    });

    Map<String, dynamic> result;

    try {
      // Adjust the endpoint URL based on your environment.
      // For local development: http://127.0.0.1:8000/api/v1/upload-image/
      // For Android Emulator: http://10.0.2.2:8000/api/v1/upload-image/
      // For iOS Simulator: http://localhost:8000/api/v1/upload-image/
      // For real devices on the same network: use your computer’s local network IP.
      final uri = Uri.parse('http://127.0.0.1:8000/api/v1/upload-image/');

      // Read the file bytes and encode them to Base64.
      final bytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create a simple POST request with a JSON body.
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"file": base64Image}),
      );

      if (response.statusCode == 200) {
        result = jsonDecode(response.body);
      } else {
        // If FastAPI doesn't respond as expected, create dummy data for testing.
        result = {
          'name': 'Dummy Analysis',
          'color': '#FF5733', // example hex color
          'context': 'dummy context',
          'summary': 'dummy summary',
          'food': 'dummy food',
          'calories': 'dummy calories',
          'recipe': 'dummy recipe',
          'error': 'No error',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Server is busy. Dummy data used for testing.")),
        );
      }
    } catch (e) {
      // In case of network error or connection issue, use dummy data.
      final resultDummy = {
        'name': 'Dummy Analysis',
        'color': '#FF5733',
        'context': 'dummy context',
        'summary': 'dummy summary',
        'food': 'dummy food',
        'calories': 'dummy calories',
        'recipe': 'dummy recipe',
        'error': 'No error',
      };
      result = resultDummy;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Server is busy. Dummy data used for testing.")),
      );
    }

    setState(() {
      _analysisResult = result;
    });

    // Create a HistoryItem with the additional name and color fields.
    final newItem = HistoryItem(
      id: DateTime.now().toString(),
      imagePath: _selectedImage!.path,
      date: DateTime.now(),
      context: result['context'],
      summary: result['summary'],
      food: result['food'],
      calories: result['calories'],
      recipe: result['recipe'],
      error: result['error'],
      name: result['name'],
      color: result['color'],
    );

    Provider.of<HistoryProvider>(context, listen: false).addItem(newItem);

    setState(() {
      _isAnalyzing = false;
      // Clear the selected image regardless of success.
      _selectedImage = null;
    });

    if (_analysisResult != null) {
      _showAnalysisDialog(_analysisResult!);
    }
  }

  Future<void> _generatePdf() async {
    if (_analysisResult == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Image Analysis Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 30),
              pw.Text('Name: ${_analysisResult!['name'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Color: ${_analysisResult!['color'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Context: ${_analysisResult!['context'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Summary: ${_analysisResult!['summary'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Food: ${_analysisResult!['food'] ?? "they are not food"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Calories: ${_analysisResult!['calories'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Recipe: ${_analysisResult!['recipe'] ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text('Error: ${_analysisResult!['error'] ?? "None"}',
                  style: pw.TextStyle(fontSize: 16)),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();

    if (kIsWeb) {
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..style.display = 'none'
        ..download =
            'analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      html.document.body!.append(anchor);
      anchor.click();
      anchor.remove();
      html.Url.revokeObjectUrl(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      try {
        final String fileName =
            'analysis_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        File file = await FileStorage.writeFileBytes(pdfBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved to: ${file.path}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save PDF: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAnalysisDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AnalysisResultDialog(
        results: results,
        onDownload: _generatePdf,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarGradientColors = [Colors.blue.shade900, Colors.indigo.shade700];
    final bodyGradientColors = isDark
        ? [
            const Color.fromARGB(255, 19, 19, 19),
            const Color.fromARGB(255, 19, 19, 19)
          ]
        : [Colors.blue.shade50, Colors.white];
    final textColor = isDark ? Colors.white : Colors.blue.shade900;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Object Analysis',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: appBarGradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: bodyGradientColors,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildImageSection(isDark, textColor),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedImage != null ? _startAnalysis : _showUploadOptions,
        icon: Icon(
          _selectedImage != null ? Icons.analytics : Icons.add_photo_alternate,
          color: Colors.white,
        ),
        label: Text(
          _selectedImage != null
              ? (_isAnalyzing ? 'Analyzing...' : 'Start Analysis')
              : 'Select Image',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            _selectedImage != null ? Colors.indigo : Colors.blue.shade900,
      ),
    );
  }

  Widget _buildImageSection(bool isDark, Color textColor) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _selectedImage != null
          ? Container(
              key: ValueKey(_selectedImage),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black45 : Colors.blue.shade100,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Selected Image',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor)),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: isDark
                                ? Colors.redAccent
                                : Colors.red.shade700),
                        onPressed: () => setState(() => _selectedImage = null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _selectedImage!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('placeholder'),
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color.fromARGB(255, 19, 19, 19)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.blue.shade100,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera, size: 40, color: textColor),
                    const SizedBox(height: 15),
                    Text('No image selected',
                        style: GoogleFonts.poppins(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
    );
  }
}

class AnalysisResultDialog extends StatelessWidget {
  final Map<String, dynamic> results;
  final VoidCallback onDownload;

  const AnalysisResultDialog({
    super.key,
    required this.results,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.blue.shade900;
    final backgroundColor = isDark ? Colors.grey[850] : Colors.white;
    final buttonColor = Colors.blue.shade900;

    // Parse the color value from the results, if provided.
    Color? resultColor;
    if (results['color'] != null) {
      try {
        final hexCode = results['color'].toString().replaceAll('#', '');
        resultColor = Color(int.parse('0xff$hexCode'));
      } catch (e) {
        resultColor = Colors.transparent;
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[800]!, Colors.grey[850]!]
                  : [Colors.blue.shade50, Colors.white],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Analysis Results',
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor)),
                    IconButton(
                      icon: Icon(Icons.download_rounded,
                          color: textColor, size: 30),
                      onPressed: onDownload,
                      tooltip: 'Download PDF Report',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // New fields: Name and Color
                Text('Name: ${results['name'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Color: ',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: resultColor ?? Colors.transparent,
                        border: Border.all(color: textColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(results['color'] ?? "N/A",
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: textColor)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Context: ${results['context'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('Summary: ${results['summary'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('Food: ${results['food'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('Calories: ${results['calories'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('Recipe: ${results['recipe'] ?? "N/A"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 10),
                Text('Error: ${results['error'] ?? "None"}',
                    style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor)),
                const SizedBox(height: 25),
                ElevatedButton.icon(
                  onPressed: onDownload,
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                  label: Text('Download Full Report',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
