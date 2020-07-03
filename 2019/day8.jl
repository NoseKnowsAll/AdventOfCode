# Import image from filename and re-interpret into multilayer image
function read_image(filename, width, height)
    file = open(filename)
    string = readline(file)
    close(file)

    n_layers = Int64(length(string)/(width*height))
    image = zeros(Int8, width, height, n_layers)
    col_counter = 1
    row_counter = 1
    lay_counter = 1
    for (index,char) in enumerate(string)
        image[col_counter, row_counter, lay_counter] = parse(Int8, char)
        col_counter += 1
        if mod(index, width) == 0
            col_counter = 1
            row_counter += 1
        end
        if mod(index, width*height) == 0
            col_counter = 1
            row_counter = 1
            lay_counter += 1
        end
    end

    return image
end

# Returns the index of the layer of the image with the least zeros digits
function min_zero_layer(image)
    min_layer = 0
    min_layer_zeros = size(image,1)*size(image,2)
    for layer = 1:size(image, 3)
        zeros = count(image[:,:,layer].==0)
        if zeros < min_layer_zeros
            min_layer_zeros = zeros
            min_layer = layer
        end
    end
    return min_layer
end

# Returns the number of 1 digits and 2 digits of a given layer
function ones_and_twos(image, layer)
    ones = 0
    twos = 0
    for row = 1:size(image,2)
        for col = 1:size(image,1)
            if image[col,row,layer] == 1
                ones += 1
            elseif image[col,row,layer] == 2
                twos += 1
            end
        end
    end
    return (ones, twos)
end

# Solves day 8-1
function least_zero_digits(filename="day8.input")
    width = 25
    height = 6
    image = read_image(filename, width, height)
    min_layer = min_zero_layer(image)
    (ones, twos) = ones_and_twos(image, min_layer)
    # Compute the product of the 1s and 2s on the layer with the minimum zeros
    return ones*twos
end

# Create full image by the top visible pixel from all layers
# 0 == black
# 1 == white
# 2 == transparent
function composite_image(all_layers)
    # Couldn't we technically have an all transparent pixel?
    image = zeros(Int8, size(all_layers,1), size(all_layers,2)) .+ 2
    for row = 1:size(all_layers,2)
        for col = 1:size(all_layers,1)
            for layer = 1:size(all_layers,3)
                if all_layers[col,row,layer] == 0
                    image[col,row] = 0
                    break
                elseif all_layers[col,row,layer] == 1
                    image[col,row] = 1
                    break
                end
            end
        end
    end
    return image
end

# Print the image to the console
function print_image(image)
    printable(color) = color == 1 ? "*" : " "
    for row = 1:size(image,2)
        for col = 1:size(image,1)
            print(printable(image[col,row]))
        end
        println()
    end
end

# Solves day 8-2
function show_image(filename="day8.input")
    width = 25
    height = 6
    all_layers = read_image(filename, width, height)
    image = composite_image(all_layers)
    print_image(image)
end
