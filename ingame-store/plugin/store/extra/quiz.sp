char g_eStore_MathOperators[][] = { "+", "-", "/", "*" };

public void eStore_GetRandomQuestion(int client, QuestionType qType) {
    if(qType == QT_Math) {
        int first   = GetRandomInt(1, 100);
        int second  = GetRandomInt(1, 100);
        int random  = GetRandomInt(0, 3);

        int answer = first;
        switch(random) {
            case 0: {
                answer = first + second;
            }
            case 1: {
                answer = first - second;
            }
            case 2: {
                answer = first / second;
            }
            case 3: {
                answer = first * second;   
            }
        }
        
        char operator[16]; FormatEx(operator, 16, g_eStore_MathOperators[random]);
        eStore_Print(client, "\x08What is \x10%s \x0A%s \x10%s\x08?", first, operator, second);
    }
    g_bIsClientTakingQuiz[client] = true;
    g_iClientQuizAnswer = answer;
    CreateTimer(10.0, eStore_QuizTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

stock Action eStore_QuizTimer(Handle tmr, any value) {
    int client = GetClientOfUserId(value);
    if(eStore_IsValidClient(client)) {
        g_iClientQuizAnswer[client] = -1;
        g_bIsClientTakingQuiz[client][QT_Math] = false;
        g_bIsClientTakingQuiz[client][QT_Facts] = false;
        
        eStore_Print(client, " \x08Too slow, you ran out of time!");
    }
    return Plugin_Stop;
}