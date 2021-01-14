# Material Browser (MBR) extension for SketchUp 2017 or newer.
# Copyright: © 2021 Samuel Tallet <samuel.tallet arobase gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3.0 of the License, or
# (at your option) any later version.
# 
# If you release a modified version of this program TO THE PUBLIC,
# the GPL requires you to MAKE THE MODIFIED SOURCE CODE AVAILABLE
# to the program's users, UNDER THE GPL.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# Get a copy of the GPL here: https://www.gnu.org/licenses/gpl.html

raise 'The MBR plugin requires at least Ruby 2.2.0 or SketchUp 2017.'\
  unless RUBY_VERSION.to_f >= 2.2 # SketchUp 2017 includes Ruby 2.2.4.

require 'sketchup'
require 'fileutils'
require 'zip'
require 'material_browser/cache'
require 'material_browser/utils'

# Material Browser plugin namespace.
module MaterialBrowser

  # Manages SketchUp Material (SKM) files.
  module SKM

    # Gets absolute path to stock materials directory.
    #
    # @raise [RuntimeError]
    #
    # @return [String]
    def self.stock_materials_path

      sketchup_year_version = Sketchup.version.to_i.to_s

      if Sketchup.platform == :platform_osx

        stock_materials_path = File.join(
          '/', 'Applications', 'SketchUp ' + '20' + sketchup_year_version,
          'SketchUp.app', 'Contents', 'Resources', 'Content', 'Materials'
        )

      elsif Sketchup.platform == :platform_win

        stock_materials_path = File.join(
          ENV['PROGRAMDATA'], 'SketchUp', 'SketchUp ' + '20' + sketchup_year_version,
          'SketchUp', 'Materials'
        )
        
      else
        raise 'Unknown operating system.'
      end

    end

    # Gets absolute path to custom materials directory.
    #
    # @raise [RuntimeError]
    #
    # @return [String]
    def self.custom_materials_path

      sketchup_year_version = Sketchup.version.to_i.to_s

      if Sketchup.platform == :platform_osx

        custom_materials_path = File.join(
          ENV['HOME'], 'Library', 'Application Support',
          'SketchUp ' + '20' + sketchup_year_version, 'SketchUp', 'Materials'
        )

      elsif Sketchup.platform == :platform_win

        custom_materials_path = File.join(
          ENV['APPDATA'], 'SketchUp', 'SketchUp ' + '20' + sketchup_year_version,
          'SketchUp', 'Materials'
        )
        
      else
        raise 'Unknown operating system.'
      end

    end

    # Extracts thumbnails from SKM files.
    # Material metadata is stored in `MaterialBrowser::SESSION`.
    def self.extract_thumbnails

      SESSION[:skm_files] = []

      Cache.create_material_thumbnails_dir

      stock_skm_glob_pattern = File.join(stock_materials_path, '**', '*.skm')
      custom_skm_glob_pattern = File.join(custom_materials_path, '**', '*.skm')

      # Fix SKM glob patterns only on Windows.
      if Sketchup.platform == :platform_win
        stock_skm_glob_pattern.gsub!('\\', '/')
        custom_skm_glob_pattern.gsub!('\\', '/')
      end
      
      skm_file_count = 0
  
      Dir.glob([stock_skm_glob_pattern, custom_skm_glob_pattern]).each do |skm_file_path|
  
        skm_file_count = skm_file_count + 1
  
        # SKM files are ZIP archive files renamed.
        Zip::File.open(skm_file_path) do |skm_file|

          skm_display_name = File.basename(skm_file_path).sub('.skm', '')

          skm_thumbnail_basename = File.basename(skm_file_path).sub(
            '.skm',
            ' #SKM-' + skm_file_count.to_s + '.png'
          )
          skm_thumbnail_path = File.join(
            Cache.material_thumbnails_path, skm_thumbnail_basename
          )
  
          skm_file.each do |skm_file_entry|

            if skm_file_entry.name == 'doc_thumbnail.png'

              # Note this method doesn't overwrite files.
              skm_file_entry.extract(skm_thumbnail_path)
            
              SESSION[:skm_files].push({

                path: skm_file_path,
                display_name: skm_display_name,
                thumbnail_uri: Utils.path2uri(skm_thumbnail_path)

              })

            end

          end
  
        end
  
      end
  
    end

    # Selects a SKM file then activates paint tool.
    #
    # @param [String] skm_file_path
    def self.select_file(skm_file_path)

      material = Sketchup.active_model.materials.load(skm_file_path)
      Sketchup.active_model.materials.current = material

      Sketchup.send_action('selectPaintTool:')

    end

  end

end