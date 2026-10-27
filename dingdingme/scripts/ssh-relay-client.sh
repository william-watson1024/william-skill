#!/usr/bin/env bash
set -u

config="${XDG_CONFIG_HOME:-$HOME/.config}/dingdingme/relay.conf"
port=''
token=''

bell() {
  if [ -w /dev/tty ]; then
    printf '\a' > /dev/tty 2>/dev/null || true
  else
    printf '\a' >&2
  fi
}

fallback() {
  printf 'Ding Ding Me: Windows relay unavailable (%s); ringing the SSH terminal instead.\n' "$1" >&2
  bell
  printf '{}\n'
  exit 0
}

if [ ! -r "$config" ]; then
  fallback "missing $config"
fi

while IFS='=' read -r key value || [ -n "${key:-}" ]; do
  value=${value%$'\r'}
  case "$key" in
    PORT) port=$value ;;
    TOKEN) token=$value ;;
  esac
done < "$config"

if [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
  fallback 'invalid relay port'
fi
if [[ ! "$token" =~ ^[[:xdigit:]]{64}$ ]]; then
  fallback 'invalid relay token'
fi
if ! command -v curl >/dev/null 2>&1; then
  fallback 'curl is unavailable'
fi

if {
  printf 'url = "http://127.0.0.1:%s/notify"\n' "$port"
  printf 'request = "POST"\n'
  printf 'header = "Authorization: Bearer %s"\n' "$token"
  printf 'max-time = 3\nfail\nsilent\nshow-error\n'
} | curl --config - >/dev/null; then
  printf '{}\n'
  exit 0
fi

fallback 'forwarded port did not accept the authenticated request'
