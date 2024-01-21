import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyAppHome(),
    );
  }
}

class MyAppHome extends StatefulWidget {
  @override
  _MyAppHomeState createState() => _MyAppHomeState();
}

class _MyAppHomeState extends State<MyAppHome> {
  List<ApplicationWithPermission> _installedApps = [];

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
  }

  Future<void> _loadInstalledApps() async {
    List<Application> apps = await DeviceApps.getInstalledApplications(
      includeAppIcons: true,
      includeSystemApps: true,
    );

    List<ApplicationWithPermission> appList = [];
    for (var app in apps) {
      Map<Permission, PermissionStatus> grantedPermissions = {};
      Map<Permission, PermissionStatus> deniedPermissions = {};

      // Use the newer 'permission' package for checking permissions
      for (var permission in Permission.values) {
        var status = await permission.request();
        if (status.isGranted) {
          grantedPermissions[permission] = status;
        } else if (status.isDenied) {
          deniedPermissions[permission] = status;
        }
      }

      appList.add(ApplicationWithPermission(
        app is ApplicationWithIcon ? app : null,
        grantedPermissions,
        deniedPermissions,
      ));
    }

    setState(() {
      _installedApps = appList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps and Permissions'),
      ),
      body: ListView.builder(
        itemCount: _installedApps.length,
        itemBuilder: (context, index) {
          ApplicationWithPermission app = _installedApps[index];
          return ListTile(
            title: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                    width: 8), // Adjust the spacing between number and icon
                if (app.app != null && app.app is ApplicationWithIcon)
                  Image.memory(app.app!.icon, width: 36, height: 36),
                const SizedBox(
                    width: 8), // Adjust the spacing between icon and app name
                Expanded(
                  child: Text(
                    app.app?.appName ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2, // Adjust the number of lines allowed
                  ),
                ),
              ],
            ),
            subtitle: Text(app.app?.packageName ?? 'Unknown'),
            onTap: () {
              _showPermissionsDialog(
                  app.grantedPermissions, app.deniedPermissions);
            },
          );
        },
      ),
    );
  }

  Future<void> _showPermissionsDialog(
    Map<Permission, PermissionStatus> grantedPermissions,
    Map<Permission, PermissionStatus> deniedPermissions,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Granted Permissions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  children: grantedPermissions.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key.toString()),
                      subtitle: Text(entry.value.toString()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Denied Permissions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Column(
                  children: deniedPermissions.entries.map((entry) {
                    return ListTile(
                      title: Text(entry.key.toString()),
                      subtitle: Text(entry.value.toString()),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ApplicationWithPermission {
  final ApplicationWithIcon? app;
  final Map<Permission, PermissionStatus> grantedPermissions;
  final Map<Permission, PermissionStatus> deniedPermissions;

  ApplicationWithPermission(
      this.app, this.grantedPermissions, this.deniedPermissions);
}
