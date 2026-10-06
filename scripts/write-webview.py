#!/usr/bin/env python3
import pathlib, re, sys, textwrap, xml.etree.ElementTree as ET

root = pathlib.Path(sys.argv[1])
url = sys.argv[2]
app_name = sys.argv[3]

def dart(s):
    return s.replace("\\","\\\\").replace("'","\\'").replace("\n","\\n")

pub = root / "pubspec.yaml"
p = pub.read_text("utf-8")
if re.search(r'(?m)^\s*webview_flutter\s*:', p):
    p = re.sub(r'(?m)^(\s*webview_flutter\s*:\s*).*$',
               r'\g<1>^4.13.0', p)
else:
    p += "\n# Added by Web2APK worker\n"
    p += "dependencies:\n" if "\ndependencies:" not in p else ""
    if "\ndependencies:" in p:
        p = re.sub(r'(\ndependencies:\s*\n)', r'\1  webview_flutter: ^4.13.0\n', p, count=1)
pub.write_text(p)

main = root / "lib/main.dart"
main.write_text(textwrap.dedent(f"""\
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Web2ApkApp());
}}

class Web2ApkApp extends StatefulWidget {{
  const Web2ApkApp({{super.key}});
  @override
  State<Web2ApkApp> createState() => _Web2ApkAppState();
}}

class _Web2ApkAppState extends State<Web2ApkApp> {{
  late final WebViewController controller;
  bool loading = true;

  @override
  void initState() {{
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => loading = true),
        onPageFinished: (_) => setState(() => loading = false),
      ))
      ..loadRequest(Uri.parse('{dart(url)}'));
  }}

  @override
  Widget build(BuildContext context) {{
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '{dart(app_name)}',
      theme: ThemeData(useMaterial3: true),
      home: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: controller),
              if (loading) const LinearProgressIndicator(minHeight: 2),
            ],
          ),
        ),
      ),
    );
  }}
}}
"""))

manifest = root / "android/app/src/main/AndroidManifest.xml"
if manifest.exists():
    s = manifest.read_text("utf-8")
    s = s.replace('<application ', '<application android:usesCleartextTraffic="true" ')
    s = re.sub(r'android:label="[^"]*"', 'android:label="'+app_name.replace('"','')+'"', s, count=1)
    manifest.write_text(s)

icon = root / "android/app/src/main/res/drawable-nodpi/app_icon.png"
# If no icon is provided, Flutter's default icon remains valid; manifest fallback is handled in workflow.
