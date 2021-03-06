// LICENSE
//
//   This software is dual-licensed to the public domain and under the following
//   license: you are granted a perpetual, irrevocable license to copy, modify,
//   publish, and distribute this file as you see fit.
//
// AUTHOR
//   Forrest Smith


#ifndef FTS_GAME_INFO_H
#define FTS_GAME_INFO_H

#include "console.h"

// internal libs
#include <net/tcp_client.h>

// lang
#include <functional>


namespace fts {

    // forward declaration
    struct GameInfoBroadcast;

    struct GameServerInfo {
        GameServerInfo(fts::GameInfoBroadcast const & gib);
        GameServerInfo(GameServerInfo const &) = default;
        GameServerInfo(GameServerInfo && other) = default;

        bool operator==(GameServerInfo const & other) const;

        const std::string ipaddr;
        const std::string hostname;
        const int32_t port;
        const int32_t processId;
    };

    struct GameConnection {
        const GameServerInfo gameInfo;
        Console console;
        fts::tcp::Client tcpClient;

        GameConnection(asio::io_service & service, fts::GameServerInfo const & info);
    };

    typedef std::vector<std::unique_ptr<fts::GameConnection>> GameConnections;

} // namespace fts

#endif // FTS_GAME_INFO_H
