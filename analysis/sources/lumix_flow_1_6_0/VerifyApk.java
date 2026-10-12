import com.android.apksig.ApkVerifier;
import java.io.File;
import java.security.MessageDigest;
import java.security.cert.X509Certificate;
import java.util.HexFormat;

class VerifyApk {
    public static void main(String[] args) throws Exception {
        for (String arg : args) {
            ApkVerifier.Result r = new ApkVerifier.Builder(new File(arg)).setMinCheckedPlatformVersion(30).build().verify();
            System.out.printf("{\"file\":\"%s\",\"verified\":%s,\"v2\":%s,\"v3\":%s,\"error_count\":%d,\"warning_count\":%d,\"cert_sha256\":[",
                new File(arg).getName(), r.isVerified(), r.isVerifiedUsingV2Scheme(), r.isVerifiedUsingV3Scheme(),
                r.getAllErrors().size(), r.getWarnings().size());
            boolean first = true;
            for (X509Certificate cert : r.getSignerCertificates()) {
                if (!first) System.out.print(",");
                System.out.print("\"" + HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(cert.getEncoded())) + "\"");
                first = false;
            }
            System.out.println("]}");
            if (!r.isVerified()) throw new IllegalStateException("APK signature verification failed for " + arg);
        }
    }
}
