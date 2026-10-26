-- Send a message from example.com through the milter and check that it is
-- signed. Run with: miltertest -s sign.lua

conn = mt.connect("inet:8891@127.0.0.1")
assert(conn, "can't connect to milter")

mt.macro(conn, SMFIC_CONNECT, "j", "mx.example.com")
assert(mt.conninfo(conn, "localhost", "127.0.0.1") == nil, "conninfo failed")

mt.macro(conn, SMFIC_MAIL, "i", "T1")
assert(mt.mailfrom(conn, "user@example.com") == nil, "mailfrom failed")
assert(mt.rcptto(conn, "dest@example.org") == nil, "rcptto failed")

assert(mt.header(conn, "From", "user@example.com") == nil, "header failed")
assert(mt.header(conn, "To", "dest@example.org") == nil, "header failed")
assert(mt.header(conn, "Subject", "test") == nil, "header failed")
assert(mt.header(conn, "Date", "Sun, 25 Oct 2026 12:00:00 +0000") == nil, "header failed")
assert(mt.eoh(conn) == nil, "eoh failed")
assert(mt.bodystring(conn, "hello\r\n") == nil, "body failed")
assert(mt.eom(conn) == nil, "eom failed")

assert(mt.eom_check(conn, MT_HDRINSERT, "DKIM-Signature") or
       mt.eom_check(conn, MT_HDRADD, "DKIM-Signature"),
       "no DKIM-Signature header added")
print("DKIM-Signature: " .. mt.getheader(conn, "DKIM-Signature", 0))

mt.disconnect(conn)
