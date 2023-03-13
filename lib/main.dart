import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:rpi_gpio/gpio.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    var routes = <String, WidgetBuilder>{
      addevice.routeName: (BuildContext context) => new addevice(title: "adddevice"),
      gpiocontrol.routeName:(BuildContext context) => new gpiocontrol(title: 'gpiocontrol')
    };
    MaterialColor mycolor =
        MaterialColor(const Color.fromRGBO(24, 134, 166, 1).value, const <int, Color>{
      50: Color.fromRGBO(24, 181, 202, 0.1),
      100: Color.fromRGBO(24, 181, 202, 0.2),
      200: Color.fromRGBO(24, 181, 202, 0.3),
      300: Color.fromRGBO(24, 181, 202, 0.4),
      400: Color.fromRGBO(24, 181, 202, 0.5),
      500: Color.fromRGBO(24, 181, 202, 0.6),
      600: Color.fromRGBO(24, 181, 202, 0.7),
      700: Color.fromRGBO(24, 181, 202, 0.8),
      800: Color.fromRGBO(24, 181, 202, 0.9),
      900: Color.fromRGBO(24, 134, 166, 1),
    });
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(primarySwatch: mycolor),
      home: const MyHomePage(title: 'Vision Prosthetics'),
      routes: routes,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  SplashScreenState createState() => SplashScreenState();
}
class SplashScreenState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5),
            ()=>Navigator.pushReplacement(context,
            MaterialPageRoute(builder:
                (context) => Bluetooth()
            )
        )
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
        color: Color.fromRGBO(24, 134, 166, 1),
        child:
        Column(children:[
          Padding(padding: EdgeInsets.only(top: 150)),
          Align(
          alignment: Alignment.center,
          child:Image.asset('test/assets/img_1.png'),
        ),
      Text('Vision Prosthetics',textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold))
      ])
    );
  }
}
class Bluetooth extends StatefulWidget{
  @override
  State<Bluetooth> createState() => _Bluetoothappstate();

}

class _Bluetoothappstate extends State<Bluetooth> {

  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  // Track the Bluetooth connection with the remote device
  late BluetoothConnection connection;

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  int _deviceState = 0;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });


    // If the Bluetooth of the device is not enabled,
    // then request permission to turn on Bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // For retrieving the paired devices list
        getPairedDevices();
      });
    });
  }
  Future<bool> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the Bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }
  List<BluetoothDevice> _devicesList = [];

  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }
  bool _connected = false;
  ListView _buildListViewOfDevices() {
    List<Widget> containers = [];
    _devicesList.forEach((device) {
      containers.add(
        SizedBox(
          height: 60,
          child: Row(
            children: <Widget>[
              Expanded(child: Column(children: [Text(device.name.toString()), Text(device.toString())])),
              ElevatedButton(
                child: const Text('Connect', style: TextStyle(color: Colors.white)),
                onPressed: () async {
      await BluetoothConnection.toAddress(device.address)
          .then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        _connected = true;
      });
      showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
              title: const Text('Device Connected'),
              content: Text('Adress of connected device: '+device.address + "\n"+'Device Name: ' + device.name.toString()),
              actions: <Widget>[
              TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
        child: const Text('Cancel'),
        ),
        TextButton(
        onPressed: () => Navigator.pop(context, 'OK'),
        child: const Text('OK'),
        )
        ]));

      });


                }),
            ],
          ),
        ),
      );
    });
    return ListView(padding: const EdgeInsets.all(8), children: <Widget>[...containers]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: NavDrawer(),
        //backgroundColor: Color.fromRGBO(24, 134, 166, 1),
        appBar: AppBar(

          title: Row(children: const <Widget>[
            Padding(
              padding: EdgeInsets.only(left: 17),
              child: Text(
                "Available Devices",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold),
              ),
            ),
          ]),
        ),
        body: Stack(children: [
          Align(
              alignment: Alignment.bottomRight,
              child: Container(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: MaterialButton(
                    onPressed: () {},
                    color: const Color.fromRGBO(24, 134, 166, 1),
                    textColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        Navigator.pushNamed(
                            context,addevice.routeName
                        );
                      },
                    ),))),
        _buildListViewOfDevices(),
    ]));
  }
}

class addevice extends StatefulWidget{

  const addevice({super.key, required this.title});
  final String title;
  static const String routeName = "/AddDevicePage";

  @override
  State<addevice> createState()=> add_device();
  }
class add_device extends State<addevice> {
  TextEditingController devicename = TextEditingController();
  TextEditingController ipadd = TextEditingController();
  TextEditingController ssh = TextEditingController();
  TextEditingController timeout = TextEditingController();
  TextEditingController username = TextEditingController();
  TextEditingController password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Device"),
      ),
      body: Center(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(padding: const EdgeInsets.all(15),
                child: TextField(
                  controller: devicename,
                  decoration: InputDecoration(
                    labelText: 'Device name',
                  ),
                ),),
                Padding(padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: ipadd,
                    decoration: InputDecoration(
                      labelText: 'Host/IP Address',
                    ),
                  ),),
                Padding(padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: ssh,
                    decoration: InputDecoration(
                      labelText: 'SSH Port',
                    ),
                  ),),
                Padding(padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: timeout,
                    decoration: InputDecoration(
                      labelText: 'Timeout',
                    ),
                  ),),
                Padding(padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                  ),),
                Padding(padding: const EdgeInsets.all(15),
                  child: TextField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: 'Password',
                    ),
                  ),)
              ],

            )
          ],
        ),
      ),
    );
  }
}

class NavDrawer extends StatelessWidget{

  @override
  Widget build(BuildContext context){
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[

          DrawerHeader(decoration: BoxDecoration(color:Color.fromRGBO(24, 134, 166, 1)),
              child: Text('Options',
              textAlign: TextAlign.center,
              style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold))
          ),
        ListTile(
            title: Text('Camera Module',textAlign: TextAlign.center,style: TextStyle(fontSize: 28,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold))
        ),
          ListTile(
              title: Text('GPIO control',textAlign: TextAlign.center,style: TextStyle(fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold)),
              onTap: (){
                Navigator.pushNamed(
                    context,gpiocontrol.routeName
                );
              }
          ),
          ListTile(
              title: Text('Settings',textAlign: TextAlign.center,style: TextStyle(fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold))
          ),
          ListTile(
              title: Text('About',textAlign: TextAlign.center,style: TextStyle(fontSize: 28,
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold))
          )
        ],
      )

    );
  }
}
class gpiocontrol extends StatefulWidget{

  const gpiocontrol({super.key, required this.title});
  final String title;
  static const String routeName = "/GPIOcontrolpage";

  @override
  State<gpiocontrol> createState()=> gpio_control();
}
late Gpio gpio;
class gpio_control extends State<gpiocontrol> {
  bool status1 = false;
  bool status2 = false;
  bool status3 = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("GPIO Control"),
      ),
    body:
        Stack(
        children: [
        Column(children:[
      Row(
          children:<Widget> [
            Padding(padding: EdgeInsets.only(right: 30)),
     Text('GPIO2',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
      Padding(padding: EdgeInsets.only(left:170 ,top:80)),
      FlutterSwitch(
    width: 110.0,
    height: 40.0,
    valueFontSize: 25.0,
    toggleSize: 45.0,
    value: status1,
    borderRadius: 30.0,
    padding: 8.0,
    showOnOff: true,
    onToggle: (val) {
    setState(() {
    status1 = val;
    }
    );})]),
          Row(
              children:<Widget> [
                Padding(padding: EdgeInsets.only(right: 30)),
                Text('GPIO3',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                Padding(padding: EdgeInsets.only(left:170 ,top:80)),
                FlutterSwitch(
                    width: 110.0,
                    height: 40.0,
                    valueFontSize: 25.0,
                    toggleSize: 45.0,
                    value: status2,
                    borderRadius: 30.0,
                    padding: 8.0,
                    showOnOff: true,
                    onToggle: (val) {
                      setState(() {
                        status2 = val;
                      }
                      );})]),
          Row(
              children:<Widget> [
                Padding(padding: EdgeInsets.only(right: 30)),
                Text('GPIO4',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                Padding(padding: EdgeInsets.only(left:170 ,top:80)),
                FlutterSwitch(
                    width: 110.0,
                    height: 40.0,
                    valueFontSize: 25.0,
                    toggleSize: 45.0,
                    value: status3,
                    borderRadius: 30.0,
                    padding: 8.0,
                    showOnOff: true,
                    onToggle: (val) {
                      final led = gpio.output(15);
                      led.value = true;
                      setState(() {
                        status3 = val;
                      }
                      );})]),
      //Padding(padding: EdgeInsets.all(20),
    //child: Text('GPIO3',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold))),
      //Padding(padding: EdgeInsets.all(20),
      //child: Text('GPIO4',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold))

    ])

        ]));
    
  }
}