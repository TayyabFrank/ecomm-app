import 'package:encrypt/encrypt.dart';

class EncryptionService {
  EncryptionService._();

  static final _key = Key.fromUtf8('your32lengthencryptionkey1234567');
  static final _iv = IV.fromLength(16);
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  static String encryptText(String value) {
    return _encrypter.encrypt(value, iv: _iv).base64;
  }

  static String decryptText(String encryptedValue) {
    try {
      return _encrypter.decrypt64(encryptedValue, iv: _iv);
    } catch (_) {
      return encryptedValue;
    }
  }
}
