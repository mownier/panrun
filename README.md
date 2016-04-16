# Panrun

An experimental game using the [Godot game engine](https://github.com/godotengine/godot).
This is inspired by the game called [Fun Run](https://itunes.apple.com/ph/app/fun-run-multiplayer-race/id547201991?mt=8).
It uses [Firebase](https://www.firebase.com/) as it's server. Using Firebase in this game is just to explore it's limitation
when it comes to gaming. Firebase has a feature that gives a certain client a nearly real-time data using server-sent events (SSE).

Before running this game, make sure you have to edit the `http_client.h` and `http_client.cpp` files of the godot engine
and then compile source code.

```cpp
// http_client.h
...
    String query_string_from_dict(const Dictionary& p_dict);
    
    // New method. Expose the property 'connection'
    Ref<StreamPeer> get_connection() const;
...
```
```cpp
// http_client.cpp
...
Ref<StreamPeer> HTTPClient::get_connection() const {
    return connection;
}

Error HTTPClient::_get_http_data(uint8_t* p_buffer, int p_bytes,int &r_received) {
...
```
```cpp
// http_client.cpp

void HTTPClient::_bind_methods() {
...
    ObjectTypeDB::bind_method(_MD("get_status"),&HTTPClient::get_status);
    ObjectTypeDB::bind_method(_MD("poll:Error"),&HTTPClient::poll);

    ObjectTypeDB::bind_method(_MD("query_string_from_dict:String","fields"),&HTTPClient::query_string_from_dict);

    // Binding the new method
    ObjectTypeDB::bind_method(_MD("get_connection"),&HTTPClient::get_connection);
...
```

