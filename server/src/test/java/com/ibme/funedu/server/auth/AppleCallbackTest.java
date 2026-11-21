package com.ibme.funedu.server.auth;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.ibme.funedu.server.TestDatabase;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestDatabase.class, TestIdTokens.class})
class AppleCallbackTest {

    @Autowired
    MockMvc mvc;

    @Test
    void handsAppleResultBackToTheAndroidApp() throws Exception {
        mvc.perform(post("/api/v1/auth/apple/callback")
                        .contentType(MediaType.APPLICATION_FORM_URLENCODED)
                        .param("code", "c1")
                        .param("id_token", "a.b.c")
                        .param("evil", "<script>"))
                .andExpect(status().isSeeOther())
                .andExpect(header().string("Location",
                        "intent://callback?code=c1&id_token=a.b.c"
                                + "#Intent;package=com.ibme.funedu;scheme=signinwithapple;end"));
    }
}
