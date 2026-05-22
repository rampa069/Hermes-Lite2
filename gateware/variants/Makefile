
HL2_VARIANTS = hl2b2_main hl2b3to4_main hl2b3to4_cicrx \
               hl2b5up_main hl2b5up_6rx hl2b5up_cicrx hl2b5up_15ce \
               hl2b5up_4000 hl2b5up_ak4951v3 hl2b5up_ak4951v4 hl2b5up_bypassversa

RB_SPI_VARIANTS = radioberry_cl016 radioberry_cl025 \
                  radioberry_cl016_4000 radioberry_cl025_4000

RB_JUICE_VARIANTS = radioberry_juice_cl016 radioberry_juice_cl025 \
                    radioberry_juice_cl016_cicrx radioberry_juice_cl025_cicrx

RB_PIO_VARIANTS = radioberry_pio_cl016 radioberry_pio_cl025

ALL_VARIANTS = $(HL2_VARIANTS) $(RB_SPI_VARIANTS) $(RB_JUICE_VARIANTS) $(RB_PIO_VARIANTS)

all:
	@for v in $(ALL_VARIANTS); do $(MAKE) -C $$v || exit 1; done

hl2:
	@for v in $(HL2_VARIANTS); do $(MAKE) -C $$v || exit 1; done

release:
	@for v in $(HL2_VARIANTS); do $(MAKE) -C $$v || exit 1; done
	python3 release.py

git_status:
	@git diff --ignore-matching-lines=LAST_QUARTUS_VERSION --exit-code >/dev/null || (echo You have unstaged changes && exit 1)
	@git diff --ignore-matching-lines=LAST_QUARTUS_VERSION --cached --exit-code >/dev/null || (echo You have staged but uncommitted changes && exit 1)
	@echo git status is clean

release_test: git_status release
	date=`date "+%Y%m%d"`; \
	gitrev=`git rev-parse --short HEAD`; \
	eval `sed -n 's/localparam.*VERSION_/VERSION_/p' ../rtl/hermeslite_core.v |sed 's/ =.* 8.d/=/'`; \
	dirname=../bitfiles/testing/"$${date}_$${VERSION_MAJOR}p$${VERSION_MINOR}_$${gitrev}"; \
	rm -rf $$dirname && mkdir $$dirname && \
	(cd release; tar cf - */*.rbf */*/*.rbf) | tar xf - -C $$dirname

radioberry:
	@for v in $(RB_SPI_VARIANTS) $(RB_JUICE_VARIANTS) $(RB_PIO_VARIANTS); do \
		$(MAKE) -C $$v || exit 1; done

radioberry-juice:
	@for v in $(RB_JUICE_VARIANTS); do $(MAKE) -C $$v || exit 1; done

clean:
	@for v in $(ALL_VARIANTS); do $(MAKE) -C $$v clean; done

realclean:
	@for v in $(ALL_VARIANTS); do $(MAKE) -C $$v realclean; done


.PHONY: all clean realclean hl2 radioberry radioberry-juice release release_test git_status
