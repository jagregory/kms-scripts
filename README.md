# KMS encryption utilities

There are several scripts here to help interact with [Amazon's Key Management Service](https://aws.amazon.com/kms/)
, without too many layers of indirection. I wanted something easily auditable and eye-ballable, without using 3rd party libraries (outside OpenSSL).

KMS has two modes:

  * *Master Key encryption* is where you use a Master Key created in KMS to directly encrypt/decrypt a secret. This mode is limited to secrets under 4k.

  * *Envelope Encryption* is where you use Master Key encryption to encrypt and decrypt another key, which you use to encrypt and decrypt files of arbitrary size outside of KMS.

There are utilities to help with both.

## The utilities

  * `kms-encrypt` - Encrypt a secret using a Master Key alias
  * `kms-decrypt` - Decrypt a secret using your Master Key
  * `kms-envelopeencrypt` - Encrypt a larger secret using `AES-256 CBC`, with a key secured through a KMS Master Key.
  * `kms-envelopedecrypt` - Decrypt a larger secret using `AES-256 CBC`, with a key secured through a KMS Master Key.

Each script can be invoked with `-h` to see it's usage.
