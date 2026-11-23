package com.ibme.funedu.server;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.Test;

/** Static safety checks over server main sources. */
class SecurityScanTest {

    private static final Path MAIN_JAVA = Path.of("src/main/java");
    private static final List<String> AUTH_WHITELIST_PATHS = List.of(
            "/auth/",
            "/actuator/health",
            "/api/v1/auth/apple/callback");

    @Test
    void everyEndpointOutsideWhitelistRequiresAuthenticationPrincipalJwt() throws Exception {
        Pattern mapping = Pattern.compile("@(Get|Post|Delete|Put|Patch)Mapping\\(([^)]*)\\)");
        Pattern classPrefix = Pattern.compile("@RequestMapping\\(\"([^\"]+)\"\\)");

        List<String> violations = new ArrayList<>();
        try (var files = Files.walk(MAIN_JAVA)) {
            for (Path p : files.filter(f -> f.toString().endsWith(".java")).toList()) {
                String src = Files.readString(p);
                String prefix = "";
                Matcher pm = classPrefix.matcher(src);
                if (pm.find()) prefix = pm.group(1);

                Matcher mm = mapping.matcher(src);
                while (mm.find()) {
                    String annArgs = mm.group(2);
                    String path = "";
                    Matcher qm = Pattern.compile("\"([^\"]+)\"").matcher(annArgs);
                    if (qm.find()) path = qm.group(1);
                    String fullPath = prefix + path;
                    if (isWhitelisted(fullPath)) continue;

                    String tail = src.substring(mm.end());
                    int openParen = findMethodOpenParen(tail);
                    int closeParen = findMatchingParen(tail, openParen);
                    if (openParen < 0 || closeParen < 0) {
                        violations.add(p + " unparseable mapping for " + fullPath);
                        continue;
                    }
                    String params = tail.substring(openParen + 1, closeParen);
                    if (!params.contains("@AuthenticationPrincipal") || !params.contains("Jwt")) {
                        violations.add(p + " endpoint " + fullPath + " missing @AuthenticationPrincipal Jwt");
                    }
                }
            }
        }
        assertThat(violations).isEmpty();
    }

    @Test
    void noSqlLiteralConcatenatesNonLiterals() throws Exception {
        Pattern sqlString = Pattern.compile(
                "\"[^\"]*\\b(SELECT|INSERT|UPDATE|DELETE)\\b[^\"]*\"(\\s*\\+\\s*([^,;)]+))?",
                Pattern.CASE_INSENSITIVE | Pattern.DOTALL);
        List<String> violations = new ArrayList<>();
        try (var files = Files.walk(MAIN_JAVA)) {
            for (Path p : files.filter(f -> f.toString().endsWith(".java")).toList()) {
                String src = Files.readString(p);
                Matcher m = sqlString.matcher(src);
                while (m.find()) {
                    if (m.group(2) == null) continue;
                    // Verify every '+' chain operand starting from this SQL literal is another string literal.
                    int pos = m.end(1);
                    String rest = src.substring(pos);
                    // Only inspect if inside an argument list where SQL concatenations appear.
                    if (hasNonStringLiteralConcat(rest)) {
                        violations.add(p + " SQL concatenation near: " + m.group(0).trim());
                    }
                }
            }
        }
        assertThat(violations).isEmpty();
    }

    private static boolean isWhitelisted(String fullPath) {
        for (String allowed : AUTH_WHITELIST_PATHS) {
            if (fullPath.startsWith(allowed) || fullPath.contains(allowed)) {
                return true;
            }
        }
        return false;
    }

    private static int findMethodOpenParen(String tail) {
        int i = 0;
        int n = tail.length();
        while (i < n) {
            char c = tail.charAt(i);
            if (Character.isWhitespace(c)) {
                i++;
            } else if (c == '@') {
                // Skip extra method annotations such as @ResponseStatus(...)
                i++;
                while (i < n && (Character.isJavaIdentifierPart(tail.charAt(i)) || tail.charAt(i) == '.')) i++;
                while (i < n && Character.isWhitespace(tail.charAt(i))) i++;
                if (i < n && tail.charAt(i) == '(') {
                    int end = findMatchingParen(tail, i);
                    if (end < 0) return -1;
                    i = end + 1;
                }
            } else {
                // Method signature return type & name until first '('
                while (i < n && tail.charAt(i) != '(') i++;
                return i < n ? i : -1;
            }
        }
        return -1;
    }

    private static int findMatchingParen(String s, int openIdx) {
        if (openIdx < 0) return -1;
        int depth = 0;
        for (int i = openIdx; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '(') depth++;
            else if (c == ')') {
                depth--;
                if (depth == 0) return i;
            }
        }
        return -1;
    }

    private static boolean hasNonStringLiteralConcat(String restAfterSqlLiteral) {
        String s = restAfterSqlLiteral.stripLeading();
        while (s.startsWith("+")) {
            s = s.substring(1).stripLeading();
            if (!s.startsWith("\"")) {
                return true;
            }
            int endQuote = 1;
            while (endQuote < s.length()) {
                char c = s.charAt(endQuote);
                if (c == '\\') {
                    endQuote += 2;
                    continue;
                }
                if (c == '"') break;
                endQuote++;
            }
            if (endQuote >= s.length()) return true;
            s = s.substring(endQuote + 1).stripLeading();
        }
        return false;
    }
}
