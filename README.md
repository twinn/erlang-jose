# JOSE

[![Build Status](https://travis-ci.org/potatosalad/erlang-jose.png?branch=master)](https://travis-ci.org/potatosalad/erlang-jose) [![Hex.pm](https://img.shields.io/hexpm/v/jose.svg)](https://hex.pm/packages/jose)

JSON Object Signing and Encryption (JOSE) for Erlang and Elixir.

## Installation

Add `jose` to your project's dependencies in `mix.exs`

```elixir
defp deps do
  [
    {:jose, "~> 1.3"}
  ]
end
```

Add `jose` to your project's dependencies in your `Makefile` for [`erlang.mk`](https://github.com/ninenines/erlang.mk) or the following to your `rebar.config`

```erlang
{deps, [
  {jose, ".*", {git, "git://github.com/potatosalad/erlang-jose.git", {branch, "master"}}}
]}.
```

#### JSON Encoder/Decoder

You will also need to specify either [jiffy](https://github.com/davisp/jiffy), [jsone](https://github.com/sile/jsone), [jsx](https://github.com/talentdeficit/jsx), or [Poison](https://github.com/devinus/poison) as a dependency.

For example, with Elixir and `mix.exs`

```elixir
defp deps do
  [
    {:jose, "~> 1.3"},
    {:poison, "~> 1.5"}
  ]
end
```

Or with Erlang and `rebar.config`

```erlang
{deps, [
  {jose, ".*", {git, "git://github.com/potatosalad/erlang-jose.git", {branch, "master"}}},
  {jsx, ".*", {git, "git://github.com/talentdeficit/jsx.git", {branch, "master"}}}
]}.
```

`jose` will attempt to find a suitable JSON encoder/decoder and will default to Poison on Elixir and jiffy, jsone, or jsx on Erlang.  If more than one are present, it will default to Poison.

You may also specify a different `json_module` as an application environment variable to `jose` or by using `jose:json_module/1` or `JOSE.json_module/1`.

#### Cryptographic Algorithm Fallback

`jose` strives to support [all](#algorithm-support) of the cryptographic algorithms specified in the [JOSE RFCs](https://tools.ietf.org/wg/jose/).

However, not all of the required algorithms are supported natively by Erlang/Elixir.  For algorithms unsupported by the native [`crypto`](http://www.erlang.org/doc/man/crypto.html) and [`public_key`](http://www.erlang.org/doc/man/public_key.html), `jose` has a pure Erlang implementation that may be used as a fallback.

See [ALGORITHMS.md](https://github.com/potatosalad/erlang-jose/blob/master/ALGORITHMS.md) for more information about algorithm support for specific OTP versions.

By default, the algorithm fallback is disabled, but can be enabled by setting the `crypto_fallback` application environment variable for `jose` to `true` or by calling `jose_jwa:crypto_fallback/1` or `JOSE.JWA.crypto_fallback/1` with `true`.

You may also review which algorithms are currently supported with the `jose_jwa:supports/0` or `JOSE.JWA.supports/0` functions.  For example, on Elixir 1.0.5 and OTP 18:

```elixir
# crypto_fallback defaults to false
JOSE.JWA.supports

[{:jwe,
  {:alg,
   ["A128GCMKW", "A128KW", "A192GCMKW", "A256GCMKW", "A256KW", "ECDH-ES",
    "ECDH-ES+A128KW", "ECDH-ES+A192KW", "ECDH-ES+A256KW", "PBES2-HS256+A128KW",
    "PBES2-HS512+A256KW", "RSA-OAEP", "RSA1_5", "dir"]},
  {:enc, ["A128CBC-HS256", "A128GCM", "A192GCM", "A256CBC-HS512", "A256GCM"]},
  {:zip, ["DEF"]}}, {:jwk, {:kty, ["EC", "RSA", "oct"]}},
 {:jws,
  {:alg,
   ["ES256", "ES384", "ES512", "HS256", "HS384", "HS512", "RS256", "RS384",
    "RS512"]}}]

# setting crypto_fallback to true
JOSE.JWA.crypto_fallback(true)

# additional algorithms are now available for use
JOSE.JWA.supports

[{:jwe,
  {:alg,
   ["A128GCMKW", "A128KW", "A192GCMKW", "A192KW", "A256GCMKW", "A256KW",
    "ECDH-ES", "ECDH-ES+A128KW", "ECDH-ES+A192KW", "ECDH-ES+A256KW",
    "PBES2-HS256+A128KW", "PBES2-HS384+A192KW", "PBES2-HS512+A256KW",
    "RSA-OAEP", "RSA-OAEP-256", "RSA1_5", "dir"]},
  {:enc,
   ["A128CBC-HS256", "A128GCM", "A192CBC-HS384", "A192GCM", "A256CBC-HS512",
    "A256GCM"]}, {:zip, ["DEF"]}}, {:jwk, {:kty, ["EC", "RSA", "oct"]}},
 {:jws,
  {:alg,
   ["ES256", "ES384", "ES512", "HS256", "HS384", "HS512", "PS256", "PS384",
    "PS512", "RS256", "RS384", "RS512"]}}]
```

## Usage

##### JSON Web Signature (JWS) of JSON Web Token (JWT) using HMAC using SHA-256 (HS256) with JSON Web Key (JWK)

_Elixir_

```elixir
# JSON Web Key (JWK)
jwk = %{
  "kty" => "oct",
  "k" => :base64url.encode("symmetric key")
}

# JSON Web Signature (JWS)
jws = %{
  "alg" => "HS256"
}

# JSON Web Token (JWT)
jwt = %{
  "iss" => "joe",
  "exp" => 1300819380,
  "http://example.com/is_root" => true
}

signed = JOSE.JWT.sign(jwk, jws, jwt)
# {%{alg: :jose_jws_alg_hmac},
#  %{"payload" => "eyJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlLCJpc3MiOiJqb2UifQ", 
#    "protected" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
#    "signature" => "shLcxOl_HBBsOTvPnskfIlxHUibPN7Y9T4LhPB-iBwM"}}

compact_signed = JOSE.JWS.compact(signed)
# {%{alg: :jose_jws_alg_hmac},
#  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlLCJpc3MiOiJqb2UifQ.shLcxOl_HBBsOTvPnskfIlxHUibPN7Y9T4LhPB-iBwM"}

verified = JOSE.JWT.verify(jwk, compact_signed)
# {true,
#  %JOSE.JWT{fields: %{"exp" => 1300819380, "http://example.com/is_root" => true,
#     "iss" => "joe"}},
#  %JOSE.JWS{alg: {:jose_jws_alg_hmac, {:jose_jws_alg_hmac, :sha256}},
#   b64: :undefined, fields: %{"typ" => "JWT"}, sph: :undefined}}

verified == JOSE.JWT.verify(jwk, signed)
# true
```

_Erlang_

```erlang
% JSON Web Key (JWK)
JWK = #{
  <<"kty">> => <<"oct">>,
  <<"k">> => base64url:encode(<<"symmetric key">>)
}.

% JSON Web Signature (JWS)
JWS = #{
  <<"alg">> => <<"HS256">>
}.

% JSON Web Token (JWT)
JWT = #{
  <<"iss">> => <<"joe">>,
  <<"exp">> => 1300819380,
  <<"http://example.com/is_root">> => true
}.

Signed = jose_jwt:sign(JWK, JWS, JWT).
% {#{alg => jose_jws_alg_hmac},
%  #{<<"payload">> => <<"eyJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlLCJpc3MiOiJqb2UifQ">>,
%    <<"protected">> => <<"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9">>,
%    <<"signature">> => <<"shLcxOl_HBBsOTvPnskfIlxHUibPN7Y9T4LhPB-iBwM">>}}

CompactSigned = jose_jws:compact(Signed).
% {#{alg => jose_jws_alg_hmac},
%  <<"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjEzMDA4MTkzODAsImh0dHA6Ly9leGFtcGxlLmNvbS9pc19yb290Ijp0cnVlLCJpc3MiOiJqb2UifQ.shLcxOl_HBBsOTvPnskfIlxHUibPN7Y9T4LhPB-iBwM">>}

Verified = jose_jwt:verify(JWK, CompactSigned).
% {true,
%     #jose_jwt{
%         fields = 
%             #{<<"exp">> => 1300819380,
%               <<"http://example.com/is_root">> => true,
%               <<"iss">> => <<"joe">>}},
%     #jose_jws{
%         alg = {jose_jws_alg_hmac,{jose_jws_alg_hmac,sha256}},
%         b64 = undefined,sph = undefined,
%         fields = #{<<"typ">> => <<"JWT">>}}}

Verified =:= jose_jwt:verify(JWK, Signed).
% true
```
##### JSON Web Encryption (JWE) of JSON Web Token (JWT) using A256GCMKW with JSON Web Key (JWK)

_Elixir_

```elixir
# JSON Web Key (JWK)
jwk = %{
  "kty" => "oct",
  "k" => :base64url.encode("symmetric key")
}

# JSON Web Encription (JWE)
jwe = %{
  "alg" => "A256GCMKW",
  "enc" => "A256GCM",
  "zip" => "DEF"
}

# JSON Web Token (JWT)
jwt = %{
  "iss" => "joe",
  "exp" => 1300819380,
  "http://example.com/is_root" => true
}

encryped = JOSE.JWT.encrypt(jwk, jwe, jwt)
compact_encryped = JOSE.JWE.compact(encrypted) |> elem(1)

JOSE.JWT.decrypt(:base64url.decode(jwk["k"]), compact_encrypted)
```
##### Reading JSON Web Keys (JWK) from PEM files

The examples below use three keys created with `openssl`:

```bash
# RSA Private Key
openssl genrsa -out rsa-2048.pem 2048

# EC Private Key (Alice)
openssl ecparam -name secp256r1 -genkey -noout -out ec-secp256r1-alice.pem

# EC Private Key (Bob)
openssl ecparam -name secp256r1 -genkey -noout -out ec-secp256r1-bob.pem
```

_Elixir_

```elixir
# RSA examples
rsa_private_jwk = JOSE.JWK.from_pem_file("rsa-2048.pem")
rsa_public_jwk  = JOSE.JWK.to_public(rsa_private_jwk)

## Sign and Verify (defaults to PS256)
message = "my message"
signed = JOSE.JWK.sign(message, rsa_private_jwk)
{true, ^message, _} = JOSE.JWK.verify(signed, rsa_public_jwk)

## Sign and Verify (specify RS256)
signed = JOSE.JWK.sign(message, %{ "alg" => "RS256" }, rsa_private_jwk)
{true, ^message, _} = JOSE.JWK.verify(signed, rsa_public_jwk)

## Encrypt and Decrypt (defaults to RSA-OAEP with A128CBC-HS256)
plain_text = "my plain text"
encrypted = JOSE.JWK.block_encrypt(plain_text, rsa_public_jwk)
{^plain_text, _} = JOSE.JWK.block_decrypt(encrypted, rsa_private_jwk)

## Encrypt and Decrypt (specify RSA-OAEP-256 with A128GCM)
encrypted = JOSE.JWK.block_encrypt(plain_text, %{ "alg" => "RSA-OAEP-256", "enc" => "A128GCM" }, rsa_public_jwk)
{^plain_text, _} = JOSE.JWK.block_decrypt(encrypted, rsa_private_jwk)

# EC examples
alice_private_jwk = JOSE.JWK.from_pem_file("ec-secp256r1-alice.pem")
alice_public_jwk  = JOSE.JWK.to_public(alice_private_jwk)
bob_private_jwk   = JOSE.JWK.from_pem_file("ec-secp256r1-bob.pem")
bob_public_jwk    = JOSE.JWK.to_public(bob_private_jwk)

## Sign and Verify (defaults to ES256)
message = "my message"
signed = JOSE.JWK.sign(message, alice_private_jwk)
{true, ^message, _} = JOSE.JWK.verify(signed, alice_public_jwk)

## Encrypt and Decrypt (defaults to ECDH-ES with A128GCM)
### Alice sends Bob a secret message using Bob's public key and Alice's private key
alice_to_bob = "For Bob's eyes only."
encrypted = JOSE.JWK.box_encrypt(alice_to_bob, bob_public_jwk, alice_private_jwk)
### Only Bob can decrypt the message using his private key (Alice's public key is embedded in the JWE header)
{^alice_to_bob, _} = JOSE.JWK.box_decrypt(encrypted, bob_private_jwk)
```

_Erlang_

```erlang
% RSA examples
RSAPrivateJWK = jose_jwk:from_pem_file("rsa-2048.pem"),
RSAPublicJWK  = jose_jwk:to_public(RSAPrivateJWK).

%% Sign and Verify (defaults to PS256)
Message = <<"my message">>,
SignedPS256 = jose_jwk:sign(Message, RSAPrivateJWK),
{true, Message, _} = jose_jwk:verify(SignedPS256, RSAPublicJWK).

%% Sign and Verify (specify RS256)
SignedRS256 = jose_jwk:sign(Message, #{ <<"alg">> => <<"RS256">> }, RSAPrivateJWK),
{true, Message, _} = jose_jwk:verify(SignedRS256, RSAPublicJWK).

%% Encrypt and Decrypt (defaults to RSA-OAEP with A128CBC-HS256)
PlainText = <<"my plain text">>,
EncryptedRSAOAEP = jose_jwk:block_encrypt(PlainText, RSAPublicJWK),
{PlainText, _} = jose_jwk:block_decrypt(EncryptedRSAOAEP, RSAPrivateJWK).

%% Encrypt and Decrypt (specify RSA-OAEP-256 with A128GCM)
EncryptedRSAOAEP256 = jose_jwk:block_encrypt(PlainText, #{ <<"alg">> => <<"RSA-OAEP-256">>, <<"enc">> => <<"A128GCM">> }, RSAPublicJWK),
{PlainText, _} = jose_jwk:block_decrypt(EncryptedRSAOAEP256, RSAPrivateJWK).

% EC examples
AlicePrivateJWK = jose_jwk:from_pem_file("ec-secp256r1-alice.pem"),
AlicePublicJWK  = jose_jwk:to_public(AlicePrivateJWK),
BobPrivateJWK   = jose_jwk:from_pem_file("ec-secp256r1-bob.pem"),
BobPublicJWK    = jose_jwk:to_public(BobPrivateJWK).

%% Sign and Verify (defaults to ES256)
Message = <<"my message">>,
SignedES256 = jose_jwk:sign(Message, AlicePrivateJWK),
{true, Message, _} = jose_jwk:verify(SignedES256, AlicePublicJWK).

%% Encrypt and Decrypt (defaults to ECDH-ES with A128GCM)
%%% Alice sends Bob a secret message using Bob's public key and Alice's private key
AliceToBob = <<"For Bob's eyes only.">>,
EncryptedECDHES = jose_jwk:box_encrypt(AliceToBob, BobPublicJWK, AlicePrivateJWK),
%%% Only Bob can decrypt the message using his private key (Alice's public key is embedded in the JWE header)
{AliceToBob, _} = jose_jwk:box_decrypt(EncryptedECDHES, BobPrivateJWK).
```

## Algorithm Support

### JSON Web Encryption (JWE) [RFC 7516](https://tools.ietf.org/html/rfc7516)

#### `"alg"` [RFC 7518 Section 4](https://tools.ietf.org/html/rfc7518#section-4)

- [X] `RSA1_5`
- [X] `RSA-OAEP`
- [X] `RSA-OAEP-256` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `A128KW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `A192KW` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `A256KW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `dir`
- [X] `ECDH-ES`
- [X] `ECDH-ES+A128KW`
- [X] `ECDH-ES+A192KW`
- [X] `ECDH-ES+A256KW`
- [X] `A128GCMKW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `A192GCMKW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `A256GCMKW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `PBES2-HS256+A128KW` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `PBES2-HS384+A192KW` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `PBES2-HS512+A256KW` <sup>[OTP-17](#footnote-otp-17)</sup>

#### `"enc"` [RFC 7518 Section 5](https://tools.ietf.org/html/rfc7518#section-5)

- [X] `A128CBC-HS256`
- [X] `A192CBC-HS384` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `A256CBC-HS512`
- [X] `A128GCM` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `A192GCM` <sup>[OTP-17](#footnote-otp-17)</sup>
- [X] `A256GCM` <sup>[OTP-17](#footnote-otp-17)</sup>

#### `"zip"` [RFC 7518 Section 7.3](https://tools.ietf.org/html/rfc7518#section-7.3)

- [X] `DEF`

### JSON Web Key (JWK) [RFC 7517](https://tools.ietf.org/html/rfc7517)

#### `"alg"` [RFC 7518 Section 6](https://tools.ietf.org/html/rfc7518#section-6)

- [X] `EC`
- [X] `RSA`
- [X] `oct`

### JSON Web Signature (JWS) [RFC 7515](https://tools.ietf.org/html/rfc7515)

#### `"alg"` [RFC 7518 Section 3](https://tools.ietf.org/html/rfc7518#section-3)

- [X] `HS256`
- [X] `HS384`
- [X] `HS512`
- [X] `RS256`
- [X] `RS384`
- [X] `RS512`
- [X] `ES256`
- [X] `ES384`
- [X] `ES512`
- [X] `PS256` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `PS384` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `PS512` <sup>[OTP-17](#footnote-otp-17), [OTP-18](#footnote-otp-18)</sup>
- [X] `none`

<sup><a name="footnote-otp-17">OTP-17</a></sup> Native algorithm not supported by OTP-17.  Use the [`crypto_fallback`](#cryptographic-algorithm-fallback) setting to enable the non-native implementation.  See [ALGORITHMS.md](https://github.com/potatosalad/erlang-jose/blob/master/ALGORITHMS.md) for more information about algorithm support for specific OTP versions.

<sup><a name="footnote-otp-18">OTP-18</a></sup> Native algorithm not supported by OTP-18.  Use the [`crypto_fallback`](#cryptographic-algorithm-fallback) setting to enable the non-native implementation.  See [ALGORITHMS.md](https://github.com/potatosalad/erlang-jose/blob/master/ALGORITHMS.md) for more information about algorithm support for specific OTP versions.
