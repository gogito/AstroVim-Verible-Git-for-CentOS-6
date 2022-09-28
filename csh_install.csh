echo "Running AstroVim - Modded by ThongNguyen for CentOS 6 CSH Install Script"
echo "1. Copying file to Home Dir"
cp -r .config .fonts .local bin lib64 libexec neovim share $HOME/
echo "Done copying file to Home Dir"
echo ""
echo "2. Set permission for copied files (chmod +x)"
chmod +x $HOME/bin/*
chmod +x $HOME/neovim/bin/*
echo "Done setting permission"
echo ""
echo "3. Add PATH to .cshrc"
touch ~/.cshrc
chmod +w ~/.cshrc
echo 'set path = ( $HOME/neovim/bin $HOME/bin $path )' >> ~/.cshrc
echo ""
echo "4. Install the font in .font to your terminal"
echo ""
echo "5. Open a new shell/terminal/tab"
echo "6. Run "nvim""