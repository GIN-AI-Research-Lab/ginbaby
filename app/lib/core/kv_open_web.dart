import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';

Future<Database> openDatabaseFile(String name) => databaseFactoryWeb.openDatabase(name);
