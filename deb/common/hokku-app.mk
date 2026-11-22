# debian/rules for a Hokku app built against the system Hokku (scripts/build-debs.sh
# copies this in as debian/hokku-app.mk). The app's rules sets PKG, APP, SIG,
# COMMENT, CATEGORIES and an install-extra target, then includes this.
ROOT := debian/$(PKG)

%:
	dh $@

override_dh_auto_clean:
	-$(MAKE) COSMOE_ROOT=/usr clean

# Hokku's Screen.h includes <Accelerant.h> since Hokku 8ec7352, and the apps'
# Makefiles don't list its folder
override_dh_auto_build:
	$(MAKE) COSMOE_ROOT=/usr CXXFLAGS="$(CXXFLAGS) -I/usr/include/os/add-ons/graphics"

override_dh_auto_test:

override_dh_auto_install: install-extra
	bash debian/hokku-deb stage $(APP) $(SIG) $(ROOT)
	bash debian/hokku-deb desktop $(APP) $(SIG) $(PKG) "$(COMMENT)" "$(CATEGORIES)" \
		Applications $(ROOT)
	install -Dm644 LICENSE $(ROOT)/usr/share/doc/$(PKG)/copyright
	bash debian/hokku-deb xattrs $(PKG) $(ROOT)

# libbe has no shlibs file (Depends names Hokku itself)
override_dh_shlibdeps:
	dh_shlibdeps -- --ignore-missing-info
