module Ivy
  # Matcher that accepts all versions of the same module as a match, i.e.
  # only checking that the module is the same.
  class IvyAllVersionMatcher
    include Java::OrgApacheIvyPluginsVersion::VersionMatcher

    def is_dynamic(askedMrid)
      false
    end

    def accept(askedMrid, foundMrid)
      true
    end

    def need_module_descriptor(askedMrid, foundMrid)
      false
    end

    def accept(askedMrid, foundMD)
      true
    end

    def compare(askedMrid, foundMrid, staticComparator)
      0
    end

    def getName
      self.class
    end
  end
end
