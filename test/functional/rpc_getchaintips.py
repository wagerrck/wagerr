#!/usr/bin/env python3
# Copyright (c) 2014-2016 The Bitcoin Core developers
# Distributed under the MIT software license, see the accompanying
# file COPYING or http://www.opensource.org/licenses/mit-license.php.
"""Test the getchaintips RPC.

- introduce a network split
- work on chains of different lengths
- join the network together again
- verify that getchaintips now returns two chain tips.
"""

from test_framework.test_framework import WagerrTestFramework
from test_framework.util import assert_equal, disconnect_nodes, connect_nodes

class GetChainTipsTest (WagerrTestFramework):
    def set_test_params(self):
        self.num_nodes = 4
        self.mn_count = 0
        self.fast_dip3_enforcement = False
        self.extra_args = [["-debug"], ["-debug"], ["-debug"], ["-debug"]]

    def run_test(self):
        tips = self.nodes[0].getchaintips()
        assert_equal(len(tips), 1)
        assert_equal(tips[0]['branchlen'], 0)
        assert_equal(tips[0]['height'], 210)
        assert_equal(tips[0]['status'], 'active')

        # Split the network and build two chains of different lengths.
        self.split_network()
        disconnect_nodes(self.nodes[0], 2)
        disconnect_nodes(self.nodes[0], 3)
        self.nodes[0].generate(10)
        self.nodes[2].generate(20)
#        self.sync_all(self.nodes[:2])
#        self.sync_all(self.nodes[2:])

        tips = self.nodes[1].getchaintips ()
        assert_equal (len (tips), 2)
        shortTip = tips[0]
        assert_equal (shortTip['branchlen'], 0)
        assert_equal (shortTip['height'], 237)
        assert_equal (tips[0]['status'], 'active')

        tips = self.nodes[3].getchaintips ()
        assert_equal (len (tips), 1)
        longTip = tips[0]
        assert_equal (longTip['branchlen'], 0)
        assert_equal (longTip['height'], 240)
        assert_equal (tips[0]['status'], 'active')
        breakpoint()
        # Join the network halves and check that we now have two tips
        # (at least at the nodes that previously had the short chain).
        connect_nodes(self.nodes[0], 2)
        connect_nodes(self.nodes[0], 3)
        tips = self.nodes[0].getchaintips ()
        assert_equal (len (tips), 1)
        assert_equal (tips[0], longTip)

        assert_equal (tips[1]['branchlen'], 0)
        assert_equal (tips[1]['status'], 'valid-fork')
        # We already checked that the long tip is the active one,
        # update data to verify that the short tip matches the expected one.
        tips[1]['branchlen'] = 0
        tips[1]['status'] = 'active'
        tips[1]['forkpoint'] = tips[1]['hash']
        assert_equal (tips[1], shortTip)

if __name__ == '__main__':
    GetChainTipsTest ().main ()
