# This code monkey patches LDAP to go through a proxy so we have a fixed range of outbound IPs when contacting
# the LDAP server. This allows some customers to have their servers behind a firewall and whitelist our IPs.
if ENV['QUOTAGUARDSTATIC_URL'].present?
  class Net::LDAP::Connection
    def initialize(server = {})
      @server = server
      @instrumentation_service = server[:instrumentation_service]

      @socket_class = server.fetch(:socket_class, ProxySocket)

      yield self if block_given?
    end
  end

  class ProxySocket < TCPSOCKSSocket
    def initialize(host, port, _socket_opts)
      super(host, port.to_i)
    end
  end

  socks = URI.parse(ENV['QUOTAGUARDSTATIC_URL'].to_s)
  TCPSOCKSSocket.socks_server = socks.host
  TCPSOCKSSocket.socks_port = 1080
  TCPSOCKSSocket.socks_username = socks.user
  TCPSOCKSSocket.socks_password = socks.password
end
