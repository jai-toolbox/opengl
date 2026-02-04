#import "Hash_Table";
#import "Basic";

/*

The main usage is for when you have some memory which can't be managed directly by alloc

I use this for gpu buffers.

*/
First_Fit_Virtual_Allocator :: struct {
    size : u32;

    // id_to_owned_region : Table(int, [2] u32);
    // these intervals include the start index and exclude the end index.
    occupied_intervals : [..] [2] u32;
}

get_size_of_previous_alloc :: (using ffva : *First_Fit_Virtual_Allocator, index: u32) -> size: u32, success: bool {

    for occupied_intervals 
        // if you had the interval [0, 4) which contains 4 elts, then 4 - 0 = 4 which is correct.
        if it[0] == index return it[1] - it[0], true;

    return 0, false;
}

// note: the start index is your pointer
// todo: should this just be called t
virtual_alloc :: (using ffva : *First_Fit_Virtual_Allocator, length: u32) -> start_index: u32, success: bool  {
    last_end : u32 = 0;

    for occupied_intervals {                                     
        // log("iterating over occupied interval");
        start := it[0];
        end := it[1];

        if (start - last_end >= length) {
            interval := u32.[last_end, last_end + length];
            array_add(*occupied_intervals, interval);
            return last_end, true; // found space before this iterations' interval
        }
        last_end = end;
    }

    // check if there's enough space after the last interval
    if (size - last_end >= length) {
        // log("there was enough space after the last end");
        interval := u32.[last_end, last_end + length];
        array_add(*occupied_intervals, interval);
        return last_end, true;
    }

    // log("not enough space after last end");

    return 0, false;
}

virtual_free :: (using ffva : *First_Fit_Virtual_Allocator, start_index: u32) -> bool {
    interval_index_to_remove := 0;

    for 0..occupied_intervals.count {
        interval := occupied_intervals[it];
        if (interval[0] == start_index) {
            // note it's ok to remove in loop here because loop ends right after.
            array_unordered_remove_by_index(*occupied_intervals, it);
            return true;
        }
    }
    return false;
}











