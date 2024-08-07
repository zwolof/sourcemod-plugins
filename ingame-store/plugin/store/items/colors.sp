enum Color {
    Color_White,
    Color_Red,
    Color_Green,
    Color_Blue,
    Color_Pink,
    Color_Yellow,
    Color_Orange
}

char eStore_ChatTextColors[_:Color][Color] = {
    "\x01", "\x0F", "\x04", "\x0C", "\x0E", "\x09", "\x10"
}

void eStore_SetChatTextColor(int client, Color color) {

}