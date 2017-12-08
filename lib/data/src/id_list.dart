import 'package:option/option.dart';
import 'a_id_data.dart';
import 'dart:collection';

class IdDataList<T extends IIdData> extends ListBase<T> {
  final List<T> l = <T>[];
  IdDataList();
  IdDataList.copy(Iterable<T> source) {
    this.addAll(source);
  }

  @override
  set length(int newLength) {
    l.length = newLength;
  }

  @override
  int get length => l.length;

  @override
  T operator [](int index) => l[index];
  @override
  void operator []=(int index, T value) {
    l[index] = value;
  }

  Option<T> getByUuid(String uuid) {
    for (T item in this) {
      if (item.id == uuid) return new Some<T>(item);
    }
    return new None<T>();
  }

  bool containsUuid(String uuid) {
    return getByUuid(uuid).any((T item) => true);
  }

  List<String> get uuidList {
    return this.map((T data) => data.id).toList();
  }

  void sortBytList(List<String> uuids) {
    for (int i = 0; i < uuids.length; i++) {
      final T item = this.getByUuid(uuids[i]).getOrElse(
          () => throw new Exception("${uuids[i]} not found in list"));
      this.remove(item);
      this.insert(i, item);
    }
  }
}
