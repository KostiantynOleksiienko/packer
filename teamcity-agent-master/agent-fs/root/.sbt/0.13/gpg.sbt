// I would prefer to use the native gpg client, but the command that gets forked
// by sbt-pgp doesn't contain the necessary flags to actually work. (incorrect
// passing of password, incorrect pub/sec ring paths, doesn't pass the key id)
// so we're left with using the builtin bouncy castle implementation.

// we also have to use the fully qualified names for things since plugins keys
// aren't automatically loaded into the sbt context and will result in sbt
// validation errors.

//com.typesafe.sbt.SbtPgp.autoImportImpl.useGpg := true
//com.typesafe.sbt.pgp.PgpKeys.gpgCommand in Global := "/usr/bin/gpg2"

com.typesafe.sbt.SbtPgp.autoImportImpl.pgpPublicRing := file("/root/.gnupg_dcos-cosmos/pubring.gpg")

com.typesafe.sbt.SbtPgp.autoImportImpl.pgpSecretRing := file("/root/.gnupg_dcos-cosmos/secring.gpg")

com.typesafe.sbt.SbtPgp.autoImportImpl.usePgpKeyHex("9C9FBDE382D0A89F")

com.typesafe.sbt.SbtPgp.autoImportImpl.pgpPassphrase := Some(Array(
  'D','y','`','Q','9','`','g','g','F','!','p','B','+','8','#','9','p','7','9','s','?','<','p',']'
))

