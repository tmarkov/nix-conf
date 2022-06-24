# Heavily based on Locate plugin by Ulrik Sverdrup <ulrik.sverdrup@gmail.com>

__kupfer_name__ = _("Recoll")
__kupfer_actions__ = (
		"Recoll",
	)
__description__ = _("Search using Recoll")
__version__ = ""
__author__ = "Honza Strnad <hanny.strnad@gmail.com>"

import subprocess

from kupfer.objects import Action, Source
from kupfer.objects import TextLeaf
from kupfer import icons, plugin_support
from kupfer import kupferstring
from kupfer.obj.objects import ConstructFileLeaf


class Recoll (Action):
	def __init__(self):
		Action.__init__(self, _("Recoll"))

	def is_factory(self):
		return True
	def activate(self, leaf):
		return RecollQuerySource(leaf.object)
	def item_types(self):
		yield TextLeaf

	def get_description(self):
		return _("Search using Recoll")
	def get_gicon(self):
		return icons.ComposedIcon("recoll", self.get_icon_name())
	def get_icon_name(self):
		return "edit-find"

class RecollQuerySource (Source):
	def __init__(self, query):
		Source.__init__(self, name=_('Results for "%s"') % query)
		self.query = query
		self.max_items = 500

	def repr_key(self):
		return self.query

	def get_items(self):
		command = ("recoll -t -q '%s'" % (self.query))
		p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)

		def get_locate_output(proc):
			out, ignored_err = proc.communicate()
			return (ConstructFileLeaf(kupferstring.fromlocale(f.split(b"\x09")[1][8:-1])) for f in out.split(b"\n")[2:-1])

		for F in get_locate_output(p):
			yield F

	def get_gicon(self):
		return icons.ComposedIcon("recoll", self.get_icon_name())
	def get_icon_name(self):
		return "edit-find"

