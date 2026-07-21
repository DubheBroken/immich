import 'dart:async';

import 'package:immich_mobile/domain/models/person.model.dart';
import 'package:immich_mobile/infrastructure/repositories/people.repository.dart';
import 'package:immich_mobile/repositories/person_api.repository.dart';
import 'package:logging/logging.dart';

final _log = Logger('DriftPeopleService');

class DriftPeopleService {
  final DriftPeopleRepository _repository;
  final PersonApiRepository _personApiRepository;

  const DriftPeopleService(this._repository, this._personApiRepository);

  Future<DriftPerson?> get(String personId) {
    return _repository.get(personId);
  }

  Future<List<DriftPerson>> getAssetPeople(String assetId) {
    return _repository.getAssetPeople(assetId);
  }

  Future<List<DriftPerson>> getAllPeople({int minFaces = 3}) {
    return _repository.getAllPeople(minFaces: minFaces);
  }

  Future<int> updateName(String personId, String name) async {
    await _personApiRepository.update(personId, name: name);
    return _repository.updateName(personId, name);
  }

  Future<int> updateBrithday(String personId, DateTime birthday) async {
    await _personApiRepository.update(personId, birthday: birthday);
    return _repository.updateBirthday(personId, birthday);
  }

  Future<bool> hidePerson(String personId) async {
    try {
      await _personApiRepository.updateVisibility(personId, isHidden: true);
      return await _repository.updateVisibility(personId, isHidden: true) > 0;
    } catch (error) {
      return false;
    }
  }

  Future<bool> showPerson(String personId) async {
    try {
      await _personApiRepository.updateVisibility(personId, isHidden: false);
      return await _repository.updateVisibility(personId, isHidden: false) > 0;
    } catch (error) {
      return false;
    }
  }

  Future<bool> mergePerson(String targetPersonId, List<String> sourcePersonIds) async {
    try {
      final result = await _personApiRepository.merge(targetPersonId, sourcePersonIds);
      if (result) {
        for (final sourceId in sourcePersonIds) {
          await _repository.deletePerson(sourceId);
        }
      }
      return result;
    } catch (error, stack) {
      _log.severe('Error merging people', error, stack);
      return false;
    }
  }
}
