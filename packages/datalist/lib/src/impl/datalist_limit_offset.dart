// Copyright (c) 2019-present,  SurfStudio LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:collection';
import 'dart:core';

import 'package:datalist/datalist.dart';
import 'package:datalist/src/datalist.dart';
import 'package:datalist/src/exceptions.dart';

/// Pagination List
/// Limit-offset mechanism
/// May merge with another DataList
///
/// @param <T> Item
class OffsetDataList<T> extends DataList<T> {
  OffsetDataList({
    this.data,
    this.limit = 0,
    this.offset = 0,
    this.totalCount = 0,
  }) : super(data);

  /// Creating an Empty DataList
  factory OffsetDataList.empty() {
    return OffsetDataList<T>(data: []);
  }

  /// Creating an empty DataList with a limit on the maximum number of elements
  factory OffsetDataList.emptyWithTotal(int totalCount) {
    return OffsetDataList(data: [], totalCount: totalCount);
  }

  /// Item count in List
  int limit;

  /// Offset relative to the first element
  int offset;

  /// Maximum number of list items
  int totalCount;

  /// List of items
  @override
  // ignore: overridden_fields
  List<T> data;

  /// Merge two DataList
  ///
  /// @param _data DataList for merge with current
  /// @return current instance
  @override
  DataList<T> merge(DataList<T> _data) {
    final OffsetDataList data = _data as OffsetDataList;

    final bool reverse = data.offset < offset;
    final List<T> merged = _tryMerge(
      (reverse ? data : this) as OffsetDataList<T>,
      (reverse ? this : data) as OffsetDataList<T>,
    );
    if (merged == null) {
      //Отрезки данных не совпадают, слияние не возможно
      throw IncompatibleRangesException('incorrect data range');
    }
    this.data.clear();
    this.data.addAll(merged);
    if (offset < data.offset) {
      limit = data.offset + data.limit - offset;
    } else if (offset == data.offset) {
      limit = data.limit;
    } else {
      offset = data.offset;
      limit = length;
    }

    totalCount = data.totalCount;
    return this;
  }

  /// Merging two DataList with removing duplicate items
  /// When you delete, the current (last sent by the server) items remain
  ///
  /// @param data              DataList for merge with current
  /// @param distinctPredicate predicate by which duplicate elements are deleted
  /// @return current instance
  // ignore: avoid_returning_this
  OffsetDataList<T> mergeWithPredicate<R>(
    OffsetDataList<T> data,
    R Function(T item) distinctPredicate,
  ) {
    final bool reverse = data.offset < offset;
    final List<T> merged =
        _tryMerge(reverse ? data : this, reverse ? this : data);
    if (merged == null) {
      throw IncompatibleRangesException('incorrect data range');
    }

    final List<T> filtered = distinctByLast(merged, distinctPredicate);
    this.data.clear();
    this.data.addAll(filtered);
    if (offset < data.offset) {
      //загрузка вниз, как обычно
      limit = data.offset + data.limit - offset;
    } else if (offset == data.offset) {
      //коллизия?
      limit = data.limit;
    } else {
      // загрузка вверх
      offset = data.offset;
      limit = length;
    }

    totalCount = data.totalCount;
    return this;
  }

  /// Converts a dataList of one type to a dataList of another type
  ///
  /// @param mapFunc mapping function
  /// @param <R>     data type of new list
  /// @return DataList<R>
  @override
  OffsetDataList<R> transform<R>(R Function(T item) mapFunc) {
    final List<R> resultData = [];
    for (final T item in this) {
      resultData.add(mapFunc.call(item));
    }

    return OffsetDataList<R>(
      data: resultData,
      limit: limit,
      offset: offset,
      totalCount: totalCount,
    );
  }

  /// Returns the offset value from which you need to start to load the next
  /// data block
  int get nextOffset => limit + offset;

  int getLimit() {
    return limit;
  }

  int getOffset() {
    return offset;
  }

  int getTotalCount() {
    return totalCount;
  }

  /// Checking the possibility of reloading data
  ///
  /// @return true/false
  @override
  bool get canGetMore => totalCount > limit + offset;

  List<T> _tryMerge(OffsetDataList<T> to, OffsetDataList<T> from) {
    if ((to.offset + to.limit) >= from.offset) {
      return _mergeLists(to.data, from.data, from.offset - to.offset);
    }

    return null;
  }

  List<T> _mergeLists(List<T> to, List<T> from, int start) {
    final List<T> result = [
      ...start < to.length ? to.sublist(0, start) : to,
      ...from,
    ];
    return result;
  }

  @override
  bool add(T value) {
    throw Exception("Unsupported operation 'add'");
  }

  @override
  bool remove(Object value) {
    throw Exception("Unsupported operation 'remove'");
  }

  bool containsAll(Iterable<dynamic> another) {
    bool contains = false;
    for (final c in another) {
      contains = data.contains(c);
    }

    return contains;
  }

  @override
  void addAll(Iterable<T> iterable) {
    throw Exception("Unsupported operation 'addAll'");
  }

  @override
  void clear() {
    super.clear();
    limit = 0;
    offset = 0;
  }

  @override
  List<T> sublist(int start, [int end]) {
    throw Exception("Unsupported operation 'sublist'");
  }

  @override
  String toString() {
    return 'DataList {limit= $limit , offset= $offset , data= $data }';
  }

  /// Removing duplicate items from source list
  /// The criterion that the elements are the same is set by the
  /// distinctPredicate parameter
  ///
  /// @param source            source list
  /// @param distinctPredicate criterion that the elements are the same
  /// @return filtered list without identical items
  List<T> distinctByLast<R>(
    List<T> source,
    R Function(T item) distinctPredicate,
  ) {
    final LinkedHashMap<R, T> resultSet = LinkedHashMap<R, T>.of({});

    for (final element in source) {
      final R key = distinctPredicate.call(element);
      resultSet[key] = element;
    }

    return resultSet.values.toList();
  }
}
