require_relative 'method_signature'

module Inch
  module CodeObject
    module Provider
      module YARD
        module Object
          # Proxy class for methods
          class MethodObject < Base
            def aliases_fullnames
              object.aliases.map(&:path)
            end

            def bang_name?
              name =~ /\!$/
            end

            def constructor?
              name == :initialize
            end

            def getter?
              attr_info = object.attr_info || {}
              read_info = attr_info[:read]
              if read_info
                read_info.path == fullname
              else
                parent.child(:"#{name}=")
              end
            end

            def has_code_example?
              signatures.any? { |s| s.has_code_example? }
            end

            def has_doc?
              signatures.any? { |s| s.has_doc? }
            end

            def method?
              true
            end

            def parameters
              @parameters ||= signatures.map(&:parameters).flatten
            end

            def parameter(name)
              parameters.detect { |p| p.name == name.to_s }
            end

            def overridden?
              !!object.overridden_method
            end

            def overridden_method
              return unless overridden?
              @overridden_method ||= YARD::Object.for(object.overridden_method)
            end

            def overridden_method_fullname
              return unless overridden?
              overridden_method.fullname
            end

            def return_mentioned?
              !return_tags.empty? || docstring.mentions_return?
            end

            def return_described?
              return_tags.any? { |t| !t.text.empty? } ||
                docstring.describes_return?
            end

            def return_typed?
              return_mentioned?
            end

            def setter?
              name =~ /\=$/ && parameters.size == 1
            end

            def signatures
              base = MethodSignature.new(self, nil)
              overloaded = overload_tags.map do |tag|
                MethodSignature.new(self, tag)
              end
              if overloaded.any? { |s| s.same?(base) }
                overloaded
              else
                [base] + overloaded
              end
            end

            def questioning_name?
              name =~ /\?$/
            end

            private

            def overload_tags
              object.tags(:overload)
            end

            def return_tags
              object.tags(:return) + overloaded_return_tags
            end

            def overloaded_return_tags
              overload_tags.map do |overload_tag|
                overload_tag.tag(:return)
              end.compact
            end
          end
        end
      end
    end
  end
end
