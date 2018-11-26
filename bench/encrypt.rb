require "benchmark/ips"
require "rbnacl"

require "ffi/hydrogen_encoder"

require_relative "./init.rb"

def suite(str)
  puts "============================ Test string length: #{str.size} ============================"

  label = "#{str.size}_char"

  hydrogen_key = ::FFI::HydrogenEncoder.hydro_secretbox_keygen
  hydrogen_context = "benched1"
  hydrogen_box = ::FFI::HydrogenEncoder::Secretbox.new(hydrogen_context, hydrogen_key)
  hydrogen_encrypted = hydrogen_box.encrypt(str)

  rbnacl_key = ::RbNaCl::Random.random_bytes(::RbNaCl::SecretBox.key_bytes)
  rbnacl_box = ::RbNaCl::SimpleBox.from_secret_key(rbnacl_key)
  rbnacl_encrypted = rbnacl_box.encrypt(str)

  Benchmark.ips do |b|
    b.time = 2
    b.warmup = 1

    b.report("hydro_secretbox_encrypt_#{label}") do |n|
      i = 0
      while i < n
        ::FFI::HydrogenEncoder.hydro_secretbox_encrypt(str, hydrogen_context, hydrogen_key)
        i += 1
      end
    end

    b.report("hydro_secretbox_decrypt_#{label}") do |n|
      i = 0
      while i < n
        ::FFI::HydrogenEncoder.hydro_secretbox_decrypt(hydrogen_encrypted, hydrogen_context, hydrogen_key)
        i += 1
      end
    end

    b.report("boxed_hydro_secretbox_encrypt_#{label}") do |n|
      i = 0
      while i < n
        hydrogen_box.encrypt(str)
        i += 1
      end
    end

    b.report("boxed_hydro_secretbox_decrypt_#{label}") do |n|
      i = 0
      while i < n
        hydrogen_box.decrypt(hydrogen_encrypted)
        i += 1
      end
    end

    b.report("boxed_rbnacl_simplebox_encrypt_#{label}") do |n|
      i = 0
      while i < n
        rbnacl_box.encrypt(str)
        i += 1
      end
    end

    b.report("boxed_rbnacl_simplebox_decrypt_#{label}") do |n|
      i = 0
      while i < n
        rbnacl_box.decrypt(rbnacl_encrypted)
        i += 1
      end
    end

    b.compare!
  end
end

TEST_STRINGS.each do |str|
  suite(str)
end
