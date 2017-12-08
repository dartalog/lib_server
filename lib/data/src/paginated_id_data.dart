import 'paginated_data.dart';
import 'id_list.dart';
import 'a_id_data.dart';

class PaginatedIdData<T extends IIdData> extends PaginatedData<T> {
  IdDataList<T> _data = new IdDataList<T>();

  @override
  IdDataList<T> get data => _data;

  PaginatedIdData();

  PaginatedIdData.copyPaginatedData(PaginatedData<T> data) {
    this.totalCount = data.totalCount;
    this.limit = data.limit;
    this.startIndex = data.startIndex;
    this._data = new IdDataList<T>.copy(data.data);
  }
}
