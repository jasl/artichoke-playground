#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

module Artichoke
  module Playground
    module Build
      RUSTFLAGS = %w[
        -C
        link-arg=-s
        -C
        link-arg=MODULARIZE=1
        -C
        link-arg=-s
        -C
        link-arg=WASM=1
        -C
        link-arg=-s
        -C
        link-arg=ENVIRONMENT=web
        -C
        link-arg=-s
        -C
        link-arg=SUPPORT_LONGJMP=1
      ].freeze

      USAGE = <<~USAGE
        build-wasm.rb - Artichoke Ruby Playground WebAssembly Builder
        Ryan Lopopolo <rjl@hyperbo.la>

        USAGE: #{$PROGRAM_NAME} [OPTIONS] [ --release ]

        OPTIONS:
            -v, --verbose
                    Emit verbose output when compiling with cargo.

      USAGE

      def self.debug(verbose: false)
        ENV['RUSTFLAGS'] = RUSTFLAGS.join(' ')
        # Rust compilation on `wasm32-unknown-emscripten` fails during linking
        # due to a dependency on missing symbol `__gxx_personality_v0`. This has
        # been broken since Rust 1.53.0 and emsdk newer than 2.0.9.
        #
        # These flags work around the problem by letting the emcc linker ignore
        # the missing symbol error.
        #
        # - https://github.com/zackradisic/cheatsheets/issues/21#issuecomment-969393554
        # - https://github.com/rust-lang/rust/issues/85821#issuecomment-969369677
        ENV['EMMAKEN_CFLAGS'] = '-s ERROR_ON_UNDEFINED_SYMBOLS=0 --no-entry'

        if verbose
          `cargo build --target wasm32-unknown-emscripten --verbose`
        else
          `cargo build --target wasm32-unknown-emscripten`
        end

        FileUtils.mv(
          ['target/wasm32-unknown-emscripten/debug/playground.js',
           'target/wasm32-unknown-emscripten/debug/playground.wasm'],
          'src/wasm/'
        )
      rescue ArgumentError, Errno::ENOENT
        # pass
      end

      def self.release(verbose: false)
        ENV['RUSTFLAGS'] = RUSTFLAGS.join(' ')
        # Rust compilation on `wasm32-unknown-emscripten` fails during linking
        # due to a dependency on missing symbol `__gxx_personality_v0`. This has
        # been broken since Rust 1.53.0 and emsdk newer than 2.0.9.
        #
        # These flags work around the problem by letting the emcc linker ignore
        # the missing symbol error.
        #
        # - https://github.com/zackradisic/cheatsheets/issues/21#issuecomment-969393554
        # - https://github.com/rust-lang/rust/issues/85821#issuecomment-969369677
        ENV['EMMAKEN_CFLAGS'] = '-s ERROR_ON_UNDEFINED_SYMBOLS=0 --no-entry'

        if verbose
          `cargo build --target wasm32-unknown-emscripten --release --verbose`
        else
          `cargo build --target wasm32-unknown-emscripten --release`
        end

        FileUtils.mv(
          ['target/wasm32-unknown-emscripten/release/playground.js',
           'target/wasm32-unknown-emscripten/release/playground.wasm'],
          'src/wasm/'
        )
      rescue ArgumentError, Errno::ENOENT
        # pass
      end

      def self.main
        args = ARGV.each_with_object({}) do |arg, memo|
          memo[arg] = arg
        end

        verbose = false
        help = false
        args.delete_if do |key, _|
          if ['-v', '--verbose'].include?(key)
            verbose = true
            next true
          end
          if ['-h', '--help'].include?(key)
            help = true
            next true
          end
          false
        end

        if help
          puts USAGE
          Process.exit(0)
        end

        argv = args.keys.freeze
        if argv == ['--release']
          release(verbose: verbose)
        elsif argv.empty?
          debug(verbose: verbose)
        else
          warn USAGE
          Process.exit(2)
        end
      end
    end
  end
end

Artichoke::Playground::Build.main if __FILE__ == $PROGRAM_NAME
