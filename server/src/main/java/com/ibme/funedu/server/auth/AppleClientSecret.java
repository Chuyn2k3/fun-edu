package com.ibme.funedu.server.auth;

import com.nimbusds.jose.JOSEException;
import com.nimbusds.jose.JWSAlgorithm;
import com.nimbusds.jose.JWSHeader;
import com.nimbusds.jose.crypto.ECDSASigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.security.KeyFactory;
import java.security.interfaces.ECPrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;

/** Apple's "client_secret": a short ES256 JWT signed with the .p8 key. */
public class AppleClientSecret {

    private final String teamId;
    private final String keyId;
    private final ECPrivateKey key;

    public AppleClientSecret(String teamId, String keyId, String pem) {
        this.teamId = teamId;
        this.keyId = keyId;
        try {
            String b64 = pem.replaceAll("-----[A-Z ]+-----", "").replaceAll("\\s", "");
            this.key = (ECPrivateKey) KeyFactory.getInstance("EC")
                    .generatePrivate(new PKCS8EncodedKeySpec(Base64.getDecoder().decode(b64)));
        } catch (Exception e) {
            throw new IllegalStateException("APPLE_PRIVATE_KEY is not a PKCS#8 EC key", e);
        }
    }

    public String forClient(String clientId, Instant now) {
        var claims = new JWTClaimsSet.Builder()
                .issuer(teamId)
                .subject(clientId)
                .audience("https://appleid.apple.com")
                .issueTime(Date.from(now))
                .expirationTime(Date.from(now.plusSeconds(300)))
                .build();
        var jwt = new SignedJWT(new JWSHeader.Builder(JWSAlgorithm.ES256).keyID(keyId).build(), claims);
        try {
            jwt.sign(new ECDSASigner(key));
        } catch (JOSEException e) {
            throw new IllegalStateException(e);
        }
        return jwt.serialize();
    }
}
