import yaml
from pathlib import Path
from io import TextIOWrapper
from sui_constants import SUI_KEYPAIR_LEN, ED25519_PUBLICKEY_BYTES_LEN, ED25519_PRIVATEKEY_BYTES_LEN, ED25519_KEYPAIR_BYTES_LEN
import base64

class SignatureScheme(IntEnum):
    """Key encoding scheme variations."""

    ED25519 = 0
    SECP256K1 = 1
    SECP256R1 = 2

    def as_str(self) -> str:
        """Get scheme as string."""
        if self is SignatureScheme.ED25519:
            return self.name
        if self is SignatureScheme.SECP256K1:
            return "Secp256k1"
        if self is SignatureScheme.SECP256R1:
            return "Secp256r1"
        raise TypeError(f"Unknown scheme {self.name}")

    @property
    def sig_scheme(self) -> str:
        """As signature scheme string."""
        return self.as_str()

def parse_config(cls, fpath: Path, config_file: TextIOWrapper) -> tuple[str, str, str, str, str]:
    """Open configuration file and generalize for ingestion."""
    kfpath = fpath.parent
    sui_config = yaml.safe_load(config_file)
    active_address = sui_config["active_address"] if "active_address" in sui_config else None
    keystore_file = Path(sui_config["keystore"]["File"]) if "keystore" in sui_config else None
    # active_env is new (0.15.0) and identifies the alias in use in the 'envs' map list
    active_env = sui_config["active_env"] if "active_env" in sui_config else None
    if not active_address or not keystore_file or not active_env:
        raise EOFError(f"{fpath} is not a valid SUI configuration file.")
    current_url = None
    # Envs is new (0.15.0), it is a list of maps, where the environment
    # contains RPC url identifed by 'aliases' (i.e. devnet, localnet)
    if "envs" in sui_config:
        for envmap in sui_config["envs"]:
            if active_env == envmap["alias"]:
                current_url = envmap["rpc"]
                break
    else:
        raise EOFError("'envs' not found in configuration file.")
    keystore_file = str(kfpath.joinpath(keystore_file.name).absolute())
    return (str(fpath), active_env, active_address, keystore_file, current_url)

def keypair_from_keystring(keystring: str) -> KeyPair:
    """keypair_from_keystring Parse keystring to keypair.

    :param keystring: base64 keystring
    :type keystring: str
    :raises SuiInvalidKeystringLength: If invalid keypair string length
    :raises NotImplementedError: If invalid keytype signature in string
    :return: keypair derived from keystring
    :rtype: KeyPair
    """
    if len(keystring) != SUI_KEYPAIR_LEN:
        raise EOFError(len(keystring))
    addy_bytes = base64.b64decode(keystring)
    if addy_bytes[0] == 0:
        return SuiKeyPairED25519.from_bytes(addy_bytes[1:])
    raise NotImplementedError

class SuiPublicKeyED25519():
    """A ED25519 Public Key."""

    def __init__(self, indata: bytes) -> None:
        """Initialize public key."""
        if len(indata) != ED25519_PUBLICKEY_BYTES_LEN:
            raise EOFError(f"Public Key expects {ED25519_PUBLICKEY_BYTES_LEN} bytes, found {len(indata)}")
        super().__init__(SignatureScheme.ED25519, indata)
        self._verify_key = VerifyKey(self.to_b64(), encoder=Base64Encoder)


class SuiPrivateKeyED25519():
    """A ED25519 Private Key."""

    def __init__(self, indata: bytes) -> None:
        """Initialize private key."""
        dlen = len(indata)
        if dlen != ED25519_PRIVATEKEY_BYTES_LEN:
            raise EOFError(f"Private Key expects {ED25519_PRIVATEKEY_BYTES_LEN} bytes, found {dlen}")
        super().__init__(SignatureScheme.ED25519, indata)
        self._signing_key = SigningKey(self.to_b64(), encoder=Base64Encoder)

    def sign(self, data: bytes, _recovery_id: int = 0) -> bytes:
        """ED25519 sign data bytes."""
        sig = self._signing_key.sign(data, encoder=RawEncoder).signature
        return sig


class SuiKeyPairED25519():
    """A SuiKey Pair."""

    def __init__(self, secret_bytes: bytes) -> None:
        """Init keypair with public and private byte array."""
        super().__init__()
        self._scheme = SignatureScheme.ED25519
        self._private_key = SuiPrivateKeyED25519(secret_bytes)
        pub_bytes = self._private_key._signing_key.verify_key
        self._public_key = SuiPublicKeyED25519(pub_bytes.encode())

    @classmethod
    def from_b64(cls, indata: str) -> KeyPair:
        """Convert base64 string to keypair."""
        if len(indata) != SUI_KEYPAIR_LEN:
            raise EOFError(f"Expect str len of {SUI_KEYPAIR_LEN}")
        base_decode = base64.b64decode(indata)
        if base_decode[0] == SignatureScheme.ED25519:
            return SuiKeyPairED25519.from_bytes(base_decode[1:])
        raise SuiInvalidKeyPair("Scheme not ED25519")

    @classmethod
    def from_bytes(cls, indata: bytes) -> KeyPair:
        """Convert bytes to keypair."""
        if len(indata) != ED25519_KEYPAIR_BYTES_LEN:
            raise EOFError(f"Expect bytes len of {ED25519_KEYPAIR_BYTES_LEN}")
        return SuiKeyPairED25519(indata)

