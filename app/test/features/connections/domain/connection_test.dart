import 'package:acalapp/features/connections/domain/connection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connection.fromJson', () {
    test('parses flat fields and nested customer/address/category when present', () {
      final json = {
        'id': 'c1',
        'customer_id': 'cust1',
        'address_id': 'addr1',
        'category_id': 'cat1',
        'active': true,
        'customer': {
          'id': 'cust1',
          'name': 'Fulano de Tal',
          'document': '12345678909',
          'membership_number': 42,
          'voter': true,
        },
        'address': {
          'id': 'addr1',
          'kind': 'Rua',
          'name': 'Principal',
        },
        'category': {
          'id': 'cat1',
          'name': 'Padrão',
          'description': null,
          'group': 'efetivo',
          'has_water_meter': true,
          'water_price': '12.5',
          'membership_price': '30.0',
        },
      };

      final connection = Connection.fromJson(json);

      expect(connection.id, 'c1');
      expect(connection.customerId, 'cust1');
      expect(connection.addressId, 'addr1');
      expect(connection.categoryId, 'cat1');
      expect(connection.active, isTrue);
      expect(connection.customer?.name, 'Fulano de Tal');
      expect(connection.address?.fullAddress, 'Rua Principal');
      expect(connection.category?.name, 'Padrão');
    });

    test('leaves nested objects null when absent from the payload', () {
      final json = {
        'id': 'c1',
        'customer_id': 'cust1',
        'address_id': 'addr1',
        'category_id': 'cat1',
        'active': false,
      };

      final connection = Connection.fromJson(json);

      expect(connection.customer, isNull);
      expect(connection.address, isNull);
      expect(connection.category, isNull);
      expect(connection.active, isFalse);
    });
  });

  group('Connection.toJson', () {
    test('emits only the flat foreign key fields, never the nested objects', () {
      const connection = Connection(
        id: 'c1',
        customerId: 'cust1',
        addressId: 'addr1',
        categoryId: 'cat1',
      );

      expect(connection.toJson(), {
        'id': 'c1',
        'customer_id': 'cust1',
        'address_id': 'addr1',
        'category_id': 'cat1',
        'active': true,
      });
    });

    test('omits the id when creating a new connection', () {
      const connection = Connection(
        customerId: 'cust1',
        addressId: 'addr1',
        categoryId: 'cat1',
      );

      expect(connection.toJson().containsKey('id'), isFalse);
    });
  });
}
