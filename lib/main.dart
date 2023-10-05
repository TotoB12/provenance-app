import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:flutter/services.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

void main() {
  OpenFoodAPIConfiguration.userAgent = UserAgent(name: 'Provenance');

  OpenFoodAPIConfiguration.globalLanguages = <OpenFoodFactsLanguage>[
    OpenFoodFactsLanguage.ENGLISH
  ];

  OpenFoodAPIConfiguration.globalCountry = OpenFoodFactsCountry.USA;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provenance',
      theme: ThemeData(
        primaryColor: Color(0xFF262626), // RGB(38, 38, 38)
      ),
      home: MyHomePage(title: 'Provenance'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String barcode = '';
  Future<String>? productNameFuture;
  int _selectedIndex = 1;
  bool isFlashOn = false;
  MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            // fontSize: 24,
            fontFamily: 'Poly',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Color(0xFF262626),
        toolbarHeight: 47.0,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[
          Container(color: Colors.white), // Search page
          Visibility(
            visible: _selectedIndex == 1,
            child: Column(
              children: <Widget>[
                Stack(
                  children: <Widget>[
                    Container(
                      height: MediaQuery.of(context).size.height * 0.3,
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            // if (barcode.format == BarcodeFormat.ean13 || barcode.format == BarcodeFormat.upcA) {
                            if (barcode.rawValue != this.barcode) {
                              setState(() {
                                this.barcode = barcode.rawValue ?? '';
                                productNameFuture =
                                    getProductInfo(this.barcode);
                              });
                              HapticFeedback.heavyImpact();
                            }
                            // }
                          }
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      left: 10.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.flip_camera_ios),
                          onPressed: () {
                            cameraController.switchCamera();
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.0,
                      right: 10.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFlashOn ? Colors.yellow : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.flash_on),
                          onPressed: () {
                            cameraController.toggleTorch();
                            HapticFeedback.lightImpact();
                            setState(() {
                              isFlashOn = !isFlashOn;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  // color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: FutureBuilder<String>(
                      future: productNameFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child:
                                  CircularProgressIndicator()); // Wrapped in Center
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          return Text(
                            '\n\n\nScanned Barcode: $barcode\n\nProduct Name: ${snapshot.data}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontFamily: 'Poly',
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ), // Scan page
          Container(color: Colors.white), // History page
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1))
        ]),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: Colors.black,
              iconSize: 37,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: Colors.grey[100]!,
              color: Colors.black,
              tabs: const [
                GButton(
                  icon: Icons.search,
                  text: 'Search',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
                GButton(
                  icon: Icons.camera_alt,
                  text: 'Scan',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
                GButton(
                  icon: Icons.history,
                  text: 'History',
                  textStyle: TextStyle(fontFamily: 'Poly'),
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                if (_selectedIndex == 1) {
                  cameraController.dispose();
                }
                if (index == 1) {
                  cameraController = MobileScannerController(
                    formats: [BarcodeFormat.ean13, BarcodeFormat.upcA],
                  );
                }
                setState(() {
                  _selectedIndex = index;
                  isFlashOn = false;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<String> getProductInfo(String barcode) async {
    ProductQueryConfiguration config = ProductQueryConfiguration(
      barcode,
      language: OpenFoodFactsLanguage.ENGLISH,
      fields: [ProductField.NAME],
      version: ProductQueryVersion.v3,
    );
    try {
      ProductResultV3 result = await OpenFoodAPIClient.getProductV3(config);
      return result.product?.productName ?? 'Unknown';
    } catch (e) {
      print('Failed to get product info: $e');
      return 'Error: Failed to get product info: $e';
    }
  }
}
