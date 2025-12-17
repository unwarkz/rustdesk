Name:       rustdesk
Version:    1.4.4
Release:    0
Summary:    RPM package
License:    GPL-3.0
URL:        https://rustdesk.com
Vendor:     rustdesk <info@rustdesk.com>
Requires:   gtk3 libxcb libxdo libXfixes alsa-lib libva2 pam gstreamer1-plugins-base
Recommends: libayatana-appindicator-gtk3

# https://docs.fedoraproject.org/en-US/packaging-guidelines/Scriptlets/

%description
The best open-source remote desktop client software, written in Rust.

%prep
# we have no source, so nothing here

%build
# we have no source, so nothing here

%global __python %{__python3}

%install
mkdir -p %{buildroot}/usr/bin/
mkdir -p %{buildroot}/usr/share/rustdesk/
mkdir -p %{buildroot}/usr/share/rustdesk/files/
mkdir -p %{buildroot}/usr/share/icons/hicolor/256x256/apps/
mkdir -p %{buildroot}/usr/share/icons/hicolor/scalable/apps/
install -m 755 $HBB/target/release/rustdesk %{buildroot}/usr/bin/rustdesk
install $HBB/libsciter-gtk.so %{buildroot}/usr/share/rustdesk/libsciter-gtk.so
install $HBB/res/fixit_connect.service %{buildroot}/usr/share/rustdesk/files/
install $HBB/res/128x128@2x.png %{buildroot}/usr/share/icons/hicolor/256x256/apps/fixit-connect.png
install $HBB/res/scalable.svg %{buildroot}/usr/share/icons/hicolor/scalable/apps/fixit-connect.svg
install $HBB/res/fixit-connect.desktop %{buildroot}/usr/share/rustdesk/files/
install $HBB/res/fixit-connect-link.desktop %{buildroot}/usr/share/rustdesk/files/

%files
/usr/bin/rustdesk
/usr/share/rustdesk/libsciter-gtk.so
/usr/share/rustdesk/files/fixit_connect.service
/usr/share/icons/hicolor/256x256/apps/fixit-connect.png
/usr/share/icons/hicolor/scalable/apps/fixit-connect.svg
/usr/share/rustdesk/files/fixit-connect.desktop
/usr/share/rustdesk/files/fixit-connect-link.desktop
/usr/share/rustdesk/files/__pycache__/*

%changelog
# let's skip this for now

%pre
# can do something for centos7
case "$1" in
  1)
    # for install
  ;;
  2)
    # for upgrade
    systemctl stop fixit_connect || true
  ;;
esac

%post
cp /usr/share/rustdesk/files/fixit_connect.service /etc/systemd/system/fixit_connect.service
cp /usr/share/rustdesk/files/fixit-connect.desktop /usr/share/applications/
cp /usr/share/rustdesk/files/fixit-connect-link.desktop /usr/share/applications/
systemctl daemon-reload
systemctl enable fixit_connect
systemctl start fixit_connect
update-desktop-database

%preun
case "$1" in
  0)
    # for uninstall
    systemctl stop fixit_connect || true
    systemctl disable fixit_connect || true
    rm /etc/systemd/system/fixit_connect.service || true
  ;;
  1)
    # for upgrade
  ;;
esac

%postun
case "$1" in
  0)
    # for uninstall
    rm /usr/share/applications/fixit-connect.desktop || true
    rm /usr/share/applications/fixit-connect-link.desktop || true
    update-desktop-database
  ;;
  1)
    # for upgrade
  ;;
esac
