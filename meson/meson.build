project('gxmicro-net',
	[ 'c', 'cpp' ] ,
	default_options: [
		'default_library=both',
		'buildtype=debugoptimized',
		'optimization=2',
		'warning_level=1',
		'debug=false',
	],
	version: '1.0'
)

pflags = []
add_project_arguments(pflags, language: [ 'c', 'cpp' ])

hdr = [
	'include',
]
hdrdirs = include_directories(hdr)
install_subdir(hdr, install_dir: 'include', strip_directory: true)

libname = 'gnet'
libsrc = [
	'lib/fpga_id.c',
	'lib/mqnic.c',
	'lib/mqnic_clk_info.c',
	'lib/mqnic_if.c',
	'lib/mqnic_port.c',
	'lib/mqnic_res.c',
	'lib/mqnic_sched_block.c',
	'lib/mqnic_scheduler.c',
	'lib/mqnic_stats.c',
	'lib/reg_block.c',
	'lib/reg_if.c',
]
libflags = []

alib = static_library(libname, libsrc,
		include_directories: hdrdirs,
		c_args: libflags,
		install: true)

appdicts = {
	'gnet-cfg': [
		'app/mqnic-config.c',
		'app/timespec.c',
	],
	'gnet-dump': [
		'app/mqnic-dump.c',
	],
	'gnet-fw': [
		'app/mqnic-fw.c',
		'app/flash.c',
		'app/flash_spi.c',
		'app/flash_bpi.c',
		'app/bitfile.c',
	],
	'gnet-xcvr': [
		'app/mqnic-xcvr.c',
		'app/drp.c',
		'app/xcvr_gt.c',
		'app/xcvr_gthe3.c',
		'app/xcvr_gtye3.c',
		'app/xcvr_gthe4.c',
		'app/xcvr_gtye4.c',
	],
}
appflags = []

foreach app, appsrc: appdicts
#	debug('@0@ =====> @1@'.format(file, app))
	executable(app, appsrc,
		c_args: appflags,
		include_directories: hdrdirs,
		link_with: alib,
		install: true)
endforeach

files = run_command('files.sh', check: false).stdout().splitlines()

foreach src: files
        obj = src.split('.')
        message('@0@ =====> @1@'.format(src, obj[0]))
        executable(obj[0], src)
endforeach

