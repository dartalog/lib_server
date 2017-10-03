import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:rpc/rpc.dart';
import 'package:tools/tools.dart';
export 'package:server/src/media_mime_resolver.dart';
import 'dart:convert';

List<List<int>> convertMediaMessagesToIntLists(List<MediaMessage> input) {
  final List<List<int>> output = <List<int>>[];
  for (MediaMessage mm in input) {
    output.add(mm.bytes);
  }
  return output;
}

String generateHash(List<int> bytes) {
  if (bytes == null || bytes.length == 0)
    throw new ArgumentError.notNull("bytes");

  final Digest hash = sha256.convert(bytes);

  return hash.toString();
}

Future<Map<String, dynamic>> loadJSONFile(String path) async {
  final File dir = new File(path);
  final String contents = await dir.readAsString();
  final Map<String, dynamic> output = JSON.decode(contents);
  return output;
}

Future<String> generateHashForFile(String path) async {
  if (isNullOrWhitespace(path)) throw new ArgumentError.notNull("path");
  final File f = new File(path);
  if (!f.existsSync()) throw new Exception("File not found");
  final Digest hash = await sha256.bind(f.openRead()).first;
  return hash.toString();
}

Future<Uint8List> getFileData(String path,
    {int maxLength: -1, int chunkSize = 100000000}) async {
  final File f = new File(path);
  if (!f.existsSync()) throw new Exception("File not found");
  RandomAccessFile raf;

  try {
    final int length = await f.length();
    final Uint8List output = new Uint8List(length);
    int toRead = length;
    if (maxLength != -1 && maxLength < toRead) toRead = maxLength;

    int i = 0;
    await for (List<int> data in f.openRead(0, toRead)) {
      output.setAll(i, data);
      i += data.length;
    }
    return output;
  } finally {
    if (raf != null) await raf.close();
  }
}

/// Performs clean-up techniques on readable IDs that have been received via the API.
///
/// Performs URI decoding, trims, and toLowerCases the string to ensure consistent readable ID formatting and matching.
String normalizeReadableId(String input) {
  if (input == null) throw new ArgumentError.notNull("input");

  String output = Uri.decodeQueryComponent(input);
  output = output.trim().toLowerCase();

  return output;
}
