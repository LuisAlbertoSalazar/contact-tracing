public with sharing class CTPersonController {

    /**
     * Generates a secure MD5 token based on a mobile number for pseudonymization.
     * @param mobile The mobile number input string.
     * @return A hexadecimal string representing the MD5 hash.
     */
    public static String getToken(String mobile) {
        // Defensive check: If no mobile is provided, return null or an empty string
        if (String.isBlank(mobile)) {
            return null; 
        }
        
        Blob targetBlob = Blob.valueOf(mobile);
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
    return EncodingUtil.convertToHex(hash);
}
}