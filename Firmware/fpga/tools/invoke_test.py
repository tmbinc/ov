#!/usr/bin/python
import argparse
import os
import fnmatch

def rdir(path):
	returns = []
	for item in os.listdir(path):
		item_path = (path + '/' + item).replace('//','/')
		if os.path.isdir(item_path):
			returns.extend(rdir(item_path))
			returns.append(item_path)
	return returns

def rmatch(path, pattern):
	returns = []
	for item in os.listdir(path):
		item_path = (path + '/' + item).replace('//','/')
		if os.path.isdir(item_path):
			returns.extend(rmatch(item_path, pattern))
		elif fnmatch.fnmatch(item, pattern):
			returns.append(item_path)
	
	return returns
			
def iverilogCompile(root, files, outname, verbose=False):
	
	cmd = ("iverilog " +
		" ".join(files) + " " +
		"-s" + root + " " +
		" ".join(
			"-I " + i for i in rdir("src/")) + " " +
		"-o " + outname)
	if verbose:
		print cmd

	rc = os.system(cmd)
	return rc == 0

def runVVP(basepath, root, verbose):
	wd = os.getcwd()

	os.chdir(wd + "/" + basepath)

	cmd = "./" + root + ".vvp -lxt2 -N"
	
	if verbose:
		print cmd

	rc = os.system(cmd)

	os.chdir(wd)

	return rc == 0

def runGTKWave(basepath, root, verbose):
	os.system("gtkwave --rcfile=tools/.gtkwaverc -A " + basepath + root + ".lxt2")

	
def main():
	ap =  argparse.ArgumentParser()
	ap.add_argument("testname")
	ap.add_argument("--show", default=False, action="store_true")
	ap.add_argument("--debug", default=False, action = "store_true")

	args = ap.parse_args()

	basepath = "test/" + args.testname + "/"
	# quick-n-dirty manifest loader
	fn = basepath + "/MANIFEST"
	src = open(fn).read()
	f = compile(src, fn, 'exec')
	
	manifest = {}
	exec f in manifest
	
	files = manifest['design_files'] + \
		map(lambda x: basepath + x, manifest['test_files'])

	root = manifest['root']

	cres = iverilogCompile(root, files, basepath + root + ".vvp", args.debug)

	if not cres:
		print "Icarus verilog compile failed, aborting!"
		return


	vvpres = runVVP(basepath, root, args.debug)

	if not vvpres:
		print "Simulation failed, aborting"
		return


	if args.show:
		runGTKWave(basepath, root, args.debug)





if __name__ == '__main__':
	main()
