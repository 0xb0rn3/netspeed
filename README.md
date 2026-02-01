# Complete installation in one command
mkdir -p ~/bin && \
curl -o ~/bin/netspeed https://raw.githubusercontent.com/0xb0rn3/netspeed/main/netspeed.sh && \
chmod +x ~/bin/netspeed && \
echo 'alias speedtest="netspeed -q"' >> ~/.zshrc && \
echo 'alias st="netspeed -q"' >> ~/.zshrc && \
echo 'alias myip="curl -s ifconfig.me && echo"' >> ~/.zshrc && \
source ~/.zshrc && \
echo "✓ NetSpeed installed! Try: speedtest"
